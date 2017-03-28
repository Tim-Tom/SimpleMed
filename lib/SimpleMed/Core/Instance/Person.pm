package SimpleMed::Core::Instance::Person;

use v5.24;

use Moose;
use Date::Simple;

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
  # trigger => observe_date('birth_date')
  trigger => observe_variable('birth_date', \&compare_undef)
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
  trigger => observe_array('emails', \&compare_undef)
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

no Moose;
__PACKAGE__->meta->make_immutable;

1;
