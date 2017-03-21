package SimpleMed::Core;

use strict;
use warnings;

use v5.22;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Try::Tiny;

use SimpleMed::Core::User;
use SimpleMed::Core::Person;
use SimpleMed::Core::Insurer;

sub LoadAll {
  SimpleMed::Core::Insurer::load($dbh);
  SimpleMed::Core::Person::load($dbh);
  SimpleMed::Core::User::load($dbh);
}

sub DumpAll {
}

1;
