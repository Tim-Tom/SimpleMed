package SimpleMed::API;

use strict;
use warnings;

use v5.22;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Dancer2;

use SimpleMed::Core::User;

sub check_session {
  # I don't really have security permissions in place right now. It's assumed everyone who
  # has a session is an admin at this point and has access to all the data.
  my $role = session('role');
  if (!defined $role) {
    send_error "Unauthorized", 401;
  }
  # elsif ...
  # send_error "Insufficient Privledges", 403;
}

sub req_login {
  my $route = shift;
  return sub {
    check_session();
    $route->();
  };
}

set serializer => 'mutable';

prefix '/users' => sub {
  post '/login' => sub {
    my $username = param('username');
    my $password = param('password');

    my $user = SimpleMed::Core::User::login($username, $password);

    session( $_ => $user->{$_} ) foreach keys %$user;

    return $user;
  };
};

prefix '/people' => sub {
  get '/:id' => req_login sub {
    my $id = param('id');
    return { id => $id };
  };
};

true;
