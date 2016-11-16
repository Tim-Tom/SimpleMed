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

my $hasher = Crypt::SaltedHash->new(algorithm => 'SHA-1');

$hasher->add('password');
my $demoPassword = $hasher->generate();
$hasher->clear();

our %cache = (
  tbollman => {
    user_id  => 1,
    username => 'tbollman',
    password => $demoPassword,
    role => 'admin'
   }
);

sub pick {
  my ($hash, @keys) = @_;
  return map { $_ => $hash->{$_} } @keys;
}

sub login($username, $password) {
  my $user = $cache{$username};
  if (!(defined $user && Crypt::SaltedHash->validate($user->{password}, $password))) {
    die {
      message => "Incorrect username or password",
      code => 401
    };
  }
  return { pick($user, qw(user_id username role)) };
}
