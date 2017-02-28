package SimpleMed::Logger::Provider::File;

use v5.24;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use AnyEvent;
use AnyEvent::IO;

sub new($class, $args) {
  my $encoding = $args->{encoding} || 'utf-8';
  my $filename = $args->{filename} or die 'filename is a required argument for file loggers';
  open(my $fh, ">>:encoding($encoding)", $filename) or die "Unable to open '$filename for append: $!";
  return new_from_fh($class, $fh);
}

sub new_from_fh($class, $fh) {
  return bless {
    fh => $fh,
    in_progress => undef,
    buffer => '',
  }, $class;
}

sub send_data($self, $formatted, $data) {
  my $proxy;
  $self->{buffer} .= $formatted;
  $self->check_write();
  1;
}

sub check_write($self) {
  my $idle;
  return if $self->{in_progress};
  return unless $self->{buffer};
  $idle = AnyEvent->idle(cb => sub {
    $self->write_data();
    $idle = undef;
  });
  $self->{in_progress} = 1;
}

sub write_data($self) {
  (my $data, $self->{buffer}) = ($self->{buffer}, '');
  aio_write $self->{fh}, $data, sub($length=0) {
    $self->{in_progress} = 0;
    $self->check_write();
  };
  1;
}

1;
