package SimpleMed::Core::Person;

use v5.22;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Crypt::SaltedHash;

our %cache;

sub load($dbh) {

};

1;
