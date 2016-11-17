use strict;
use warnings;

use String::Random;
use Crypt::SaltedHash;

use Test::More tests => 9;
use Test::Exception;

use_ok 'SimpleMed::Core::User';

my $plaintext = String::Random->new()->randpattern('.'x16);

my $cryptext = do {
  my $hasher = Crypt::SaltedHash->new(algorithm => 'SHA-1');
  $hasher->add($plaintext);
  my $res =$hasher->generate();
  $hasher->clear();
  $res;
};

my $user = {
  user_id  => 123,
  username => 'test_user',
  password => $cryptext,
  status => 'active'
};

local %SimpleMed::Core::User::cache;
%SimpleMed::Core::User::cache = ($user->{username} => $user);

dies_ok(sub { SimpleMed::Core::User::login() }, 'No Arguments');
dies_ok(sub { SimpleMed::Core::User::login($user->{username}) }, 'No Password');
dies_ok(sub { SimpleMed::Core::User::login('baduser', $plaintext) }, 'Nonexistant user');
dies_ok(sub { SimpleMed::Core::User::login($user->{username}, $plaintext . 'abc') }, 'Bad Password');
my $result;
lives_ok(sub { $result = SimpleMed::Core::User::login($user->{username}, $plaintext) }, 'Valid Login');

is($result->{username}, $user->{username}, 'Username Matches');
is($result->{status}, $user->{status}, 'Status Matches');
is($result->{password}, undef, 'Password not returned');
