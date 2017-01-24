package SimpleMed::API;

use strict;
use warnings;

use v5.22;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Dancer2;

use Try::Tiny;

use SimpleMed::Core::User;
use SimpleMed::Core::Person;

sub check_session {
  # I don't really have security permissions in place right now. It's assumed everyone who
  # has a session is an admin at this point and has access to all the data.
  my $role = session('user_id');
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

    my $user;
    try {
      $user = SimpleMed::Core::User::login($username, $password);
    } catch {
      send_error($_->{message}, $_->{code});
    };

    session( $_ => $user->{$_} ) foreach keys %$user;

    $user->{session} = session()->{id};

    return $user;
  };
};

prefix '/people' => sub {
  get '/' => sub {
    return [SimpleMed::Core::Person::get()];
  };
  get '/:id' => sub {
    my $id = param('id');
    my $result = SimpleMed::Core::Person::find_by_id($id);
    if (!defined $result) {
      send_error('Person does not exist', 404);
    }
    return $result;
  };
};

true;
