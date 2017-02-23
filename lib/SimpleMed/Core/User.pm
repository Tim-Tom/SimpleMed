package SimpleMed::Core::User;

use v5.22;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Crypt::SaltedHash;

use SimpleMed::Common qw(omit);

our %cache;

my @db_keys = qw(user_id username password status);
my $db_columns = join(', ', @db_keys);

sub load($dbh) {
  my @rows = $dbh->execute("SELECT $db_columns FROM app.users");
  for my $row (@rows) {
    my $user = { map { $db_keys[$_] => $row->[$_] } 0 .. $#db_keys };
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
