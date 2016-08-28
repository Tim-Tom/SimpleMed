package SimpleMed::API;

use strict;
use warnings;

use Dancer2;
set serializer => 'mutable';

use Crypt::SaltedHash;

my $hasher = Crypt::SaltedHash->new(algorithm => 'SHA-1');

my $demoPassword;

$hasher->add('password');
$demoPassword = $hasher->generate();
$hasher->clear();


post '/login' => sub {
  my $username = param('username');
  my $password = param('password');

  my $user = {
    username => $username,
    password => $demoPassword
   };

  if (!Crypt::SaltedHash->validate($user->{password}, $password)) {
    send_error "Incorrect username or password", 401;
  }

  session(
    user => $username,
    role => 'user'
   );

  return $user;
};

true;
