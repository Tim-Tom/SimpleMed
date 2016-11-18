package SimpleMed::Core::User;

use v5.22;

use strict;
use warnings;

use Dancer2;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Crypt::SaltedHash;

use SimpleMed::Common qw(omit);

our %cache;

sub load($dbh) {
  my $sth = $dbh->prepare('SELECT user_id, username, password, status FROM app.users') or die {message => $dbh->errstr, code => 500 };
  $sth->execute() or die {message => $sth->errstr, code => 500 };
  while(my $user = $sth->fetchrow_hashref()) {
    $cache{$user->{username}} = $user;
  }
  return scalar keys %cache;
}

sub login($username, $password) {
  my $user = $cache{$username};
  if (!(defined $user && Crypt::SaltedHash->validate($user->{password}, $password))) {
    die {
      message => "Incorrect username or password",
      code => 401
    };
  }
  return omit($user, qw(password));
}

1;
