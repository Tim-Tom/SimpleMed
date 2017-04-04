package SimpleMed::Core::Instance::Person;

use v5.24;

use Moose;
use Date::Simple;

use Scalar::Util qw(blessed);

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use SimpleMed::Observer qw(:compare :observe);

has 'id' => (
  is => 'ro',
  isa => 'Int',
  required => 1
);

has 'first_name' => (
  is => 'rw',
  isa => 'Str',
  required => 1,
  trigger => observe_string('first_name')
);

has 'middle_name' => (
  is => 'rw',
  isa => 'Str',
  default => '',
  trigger => observe_string('middle_name')
);

has 'last_name' => (
  is => 'rw',
  isa => 'Str',
  required => 1,
  trigger => observe_string('last_name')
);

has 'gender' => (
  is => 'rw',
  isa => 'Str',
  trigger => observe_string('gender')
);

has 'birth_date' => (
  is => 'rw',
  isa => 'Date::Simple',
  trigger => observe_date('birth_date')
);

has 'time_zone' => (
  is => 'rw',
  isa => 'Str',
  default => 'America/Los_Angeles',
  trigger => observe_string('time_zone')
);

has 'addresses' => (
  is => 'rw',
  default => sub { [] },
  trigger => observe_array('addresses', \&compare_undef)
);

has 'emails' => (
  is => 'rw',
  default => sub { [] },
  trigger => observe_array('emails', \&compare_string)
);

has 'phones' => (
  is => 'rw',
  default => sub { [] },
  trigger => observe_array('phones', \&compare_undef)
);

has 'emergency_contacts' => (
  is => 'rw',
  default => sub { [] },
  trigger => observe_array('emergency_contacts', \&compare_undef)
);

has 'insurer' => (
  is => 'rw',
  trigger => observe_variable('insurer', \&compare_undef)
);


sub FREEZE($self) {
  my $frozen = {};
  for my $attr ($self->meta->get_all_attributes) {
    if ($attr->name eq 'emergency_contacts') {
      $frozen->{$attr->name} = [map { $_->id } @{$self->emergency_contacts}];
    } else {
      my $v = $attr->get_value($self);
      if (defined $v && defined blessed($v) && $v->can('FREEZE')) {
        $v = $v->FREEZE();
      }
      $frozen->{$attr->name} = $v;
    }
  }
  return $frozen;
}

sub THAW($class, $frozen) {
  my (%args, %connectors);
  for my $attr (__PACKAGE__->meta->get_all_attributes) {
    my $name = $attr->name;
    if ($name eq 'emergency_contacts') {
      if (@{$frozen->{$name}}) {
        $connectors{$name} = $frozen->{$name};
      }
    } elsif ($attr->name eq 'insurer') {
      # TODO: need insurer class
    } else {
      $args{$name} = $frozen->{$name};
    }
  }
  return $class->new(\%args), %connectors ? \%connectors : undef;
}

sub CONNECT($self, $connectors) {
  # TODO: need global repository
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
