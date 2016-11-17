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

sub load_all($dbh) {
  SimpleMed::Core::Person::load($dbh);
  SimpleMed::Core::User::load($dbh);
}

1;
