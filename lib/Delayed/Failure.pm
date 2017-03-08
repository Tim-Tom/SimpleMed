package Delayed::Failure;

use strict;
use warnings;

use Carp;

our $AUTOLOAD;

sub new {
  my ($class, $error) = @_;
  return bless \$error, $class;
}

# It's in all caps because it's used for magic. If you want to change the default
# handling, which is just to print the error message provided, you can do
# *Delayed::Failure::ERROR_METHOD = sub { ... } or you can subclass
sub ERROR_METHOD {
  my ($self, $method) = @_;
  croak($$self);
}

sub AUTOLOAD {
  my $self = shift;
  my $method = substr($AUTOLOAD, rindex($AUTOLOAD, ':') + 1);
  @_ = ($self, $method);
  goto $self->can('ERROR_METHOD');
}

# Need to make an explicit destroy handler or else autoload will fire on it.
sub DESTROY { }

package Delayed::Failure::TiedScalar;

# So the way this works is that you tie the scalar to this class. If the thing stored in
# the class is an instance of Delayed::Failure, it will fail on fetching the value. This
# class does not work with dynamic scoping. The way that local performs is that it will
# fetch the value, save a backup, then restore it when it drops out of scope. Since it
# attempts to fetch the value, we will throw our failure and bad things will happen.

sub TIESCALAR {
  my ($class, $error) = @_;
  if (ref($error)) {
    if (ref($error)->isa('Delayed::Failure')) {
      die "Not sure what TiedScalar constructor got passed, but it doesn't look like an error message";
    }
  } else {
    $error = Delayed::Failure->new($error);
  }
  return bless \$error, $class;
}

sub STORE {
  my ($self, $value) = @_;
  $$self = $value;
}

sub FETCH {
  my ($self, ) = @_;
  if (ref($$self) && $$self->isa('Delayed::Failure')) {
    @_ = ($$self, 'FETCH');
    goto $_[0]->can('ERROR_METHOD');
  }
  return $$self;
}

1;
