use strict;
use warnings;

use v5.24;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Test::More tests => 8;
use Test::Exception;

use SimpleMed::Observer;
use List::Util qw(pairgrep);

my $difference;

sub diff_ok($sub, $message) : prototype(&$) {
  $difference = 0;
  $sub->();
  is($difference, 1, $message);
}

sub same_ok($sub, $message) : prototype(&$) {
  $difference = 0;
  $sub->();
  is($difference, 0, $message);
}

{
  no warnings;
  *SimpleMed::Observer::found_difference = sub {
    $difference = 1;
  };
}

use_ok('SimpleMed::Core::Instance::Person');

my @default = (id => 1, first_name => 'Joe', last_name => 'User');

dies_ok { SimpleMed::Core::Instance::Person->new(); } 'empty constructor fails';
for my $i (map { $_ * 2 } 0 .. (@default / 2) - 1) {
  my $key = $default[$i];
  my @args = @default[0 .. $i - 1, $i + 2 .. $#default];
  dies_ok { SimpleMed::Core::Instance::Person->new(@args); } "$key required";
}

my $person;
lives_ok { $person = SimpleMed::Core::Instance::Person->new(@default) } 'others optional';
subtest 'Person Valid' => sub {
  plan tests => 14;
  ok(defined $person, 'Person is defined');
  is($difference, 1, 'Difference flagged on constructor');
  is($person->id, 1, 'Id set');
  is($person->first_name, 'Joe', 'first_name set');
  is($person->middle_name, '', 'middle_name defaulted');
  is($person->last_name, 'User', 'last_name set');
  ok(!defined $person->gender, 'gender not set');
  ok(!defined $person->birth_date, 'birth date not set');
  is($person->time_zone, 'America/Los_Angeles', 'time zone defaulted');
  is(scalar @{$person->addresses}, 0, 'addresses empty');
  is(scalar @{$person->emails}, 0, 'emails empty');
  is(scalar @{$person->phones}, 0, 'phones empty');
  is(scalar @{$person->emergency_contacts}, 0, 'emergency_contacts empty');
  ok(!defined $person->insurer, 'insurer not set');
};

subtest 'Observation' => sub {
  plan tests => 18;
  dies_ok { $person->id(10);              } 'id read only';
  diff_ok { $person->first_name('Bob');   } 'first_name diff';
  same_ok { $person->first_name('Bob');   } 'first_name same';
  diff_ok { $person->middle_name('J');    } 'middle_name diff';
  same_ok { $person->middle_name('J');    } 'middle_name diff';
  diff_ok { $person->last_name('Person'); } 'last_name diff';
  same_ok { $person->last_name('Person'); } 'last_name same';
  diff_ok { $person->gender('Female');    } 'gender set';
  diff_ok { $person->gender('Male');      } 'gender diff';
  same_ok { $person->gender('Male');      } 'gender same';
  diff_ok { $person->birth_date(Date::Simple::ymd(1970, 1, 1)); } 'birth_date set';
  diff_ok { $person->birth_date(Date::Simple->today); } 'birth_date diff';
  same_ok { $person->birth_date(Date::Simple->today); } 'birth_date same';
  diff_ok { $person->time_zone('America/New_York'); } 'time_zone diff';
  same_ok { $person->time_zone('America/New_York'); } 'time_zone same';
  # Todo address
  diff_ok { $person->emails(['Bob.J.Person@example.org', 'Bob.J.Person.1970@example.org']); } 'emails diff size';
  diff_ok { $person->emails(['Bob.J.Person.1970@example.org', 'Bob.J.Person@example.org']); } 'emails diff content';
  same_ok { $person->emails(['Bob.J.Person.1970@example.org', 'Bob.J.Person@example.org']); } 'emails same';
  # Todo phones
  # Todo emergency contacts
  # todo insurer
};
