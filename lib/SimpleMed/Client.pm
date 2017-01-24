package SimpleMed::Client;

use strict;
use warnings;

use Dancer2;
use Dancer2::Plugin::Database;

use SimpleMed::Common qw(diff);

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

get '/people/new' => req_login sub {
  my $result = {
    person_id => 'new',
    time_zone => 'America/Los_Angeles'
   };
  template 'editPerson/details', $result;
};

get '/people/:id' => req_login sub {
  my $id = param('id');
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    send_error('Person does not exist', 404);
  }
  template 'person', $result;
};

get '/people/:id/editDetails' => req_login sub {
  my $id = param('id');
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    send_error('Person does not exist', 404);
  }
  template 'editPerson/details', $result;
};

sub uparam {
  return param(@_) || undef;
}

sub read_params_flat {
  return { map { $_ => uparam($_) } @_ };
}

my @detail_keys = qw(first_name middle_name last_name gender birth_date time_zone);

post '/people/new' => req_login sub {
  my ($new, $final);
  $new = read_params_flat @detail_keys;
  $final = SimpleMed::Core::Person::create(database(), $new);
  redirect('/people/' . $final->{person_id});
};

post '/people/:id/editDetails' => req_login sub {
  my $id = param('id');
  my ($original, $new, $final);
  $new = read_params_flat @detail_keys;
  $original = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $original) {
    send_error('Person does not exist', 404);
  }
  my @d = diff($original, $new, @detail_keys);
  if (@d) {
    $final = SimpleMed::Core::Person::update(database(), $id, $new, @d);
  } else {
    $final = $original;
  }
  redirect('/people/' . $final->{person_id});
};

get '/people/:id/editAddresses' => req_login sub {
  my $id = param('id');
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    send_error('Person does not exist', 404);
  }
  template 'editPerson/addresses', $result;
};

get '/people/:id/editPhones' => req_login sub {
  my $id = param('id');
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    send_error('Person does not exist', 404);
  }
  template 'editPerson/phones', $result;
};

get '/people/:id/editEmails' => req_login sub {
  my $id = param('id');
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    send_error('Person does not exist', 404);
  }
  template 'editPerson/emails', $result;
};

true;
