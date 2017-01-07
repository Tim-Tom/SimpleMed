package SimpleMed::Client;

use strict;
use warnings;

use Dancer2 appname => 'SimpleMed';

use Try::Tiny;

sub check_session {
  # I don't really have security permissions in place right now. It's assumed everyone who
  # has a session is an admin at this point and has access to all the data.
  my $role = session('user_id');
  if (!defined $role) {
    forward('/login', { destination => request->dispatch_path });
  }
  # elsif ...
  # send_error "Insufficient Privledges", 403;
}

sub req_login(&) {
  my $route = shift;
  return sub {
    check_session();
    $route->();
  };
}

get '/' => req_login sub {
  forward '/people';
};

get '/info' => req_login sub {
  template 'info';
};

get '/login' => sub {
  template 'login', { error => '', destination => param('destination') || '/' };
};

post '/login' => sub {
  my $username = param('username');
  my $password = param('password');

  my ($user, $login_error);
  try {
    $user = SimpleMed::Core::User::login($username, $password);
  } catch {
    $login_error = "$_->{code}: $_->{message}";
  };

  return (template 'login', { banner => { type => 'notification', message => $login_error }, destination => param('destination') || '/', username => $username }) if $login_error;

  session( $_ => $user->{$_} ) foreach keys %$user;

  redirect param('destination') || '/';
};

get '/people' => req_login sub {
  template 'people', { people => [SimpleMed::Core::Person::get()] };
};

get '/people/:id' => req_login sub {
  my $id = param('id');
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    send_error('Person does not exist', 404);
  }
  template 'person', $result;
};

true;
