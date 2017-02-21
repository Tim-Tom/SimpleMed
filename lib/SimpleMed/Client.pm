package SimpleMed::Client;

use v5.24;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Try::Tiny;

use WWW::Form::UrlEncoded qw(build_urlencoded);

use Unicode::UTF8 qw(encode_utf8);

use SimpleMed::Common qw(diff);
use SimpleMed::Template;
use SimpleMed::Core;

use Data::Printer;

our @Routes;

sub get($path, $route) {
  my $repath = quotemeta $path;
  my $handler;
  if ($repath =~ s!\\:(\w+)!(?<$1>[^/]+)!g) {
    $handler = sub($req, $env) {
      $route->($req, $env, %+);
    };
  } else {
    $handler = $route;
  }
  $repath = qr/^$repath$/;
  push(@Routes, ['GET', $repath, $handler]);
}

sub post($path, $route) {
  my $repath = quotemeta $path;
  my $handler;
  if ($repath =~ s!\\:(\w+)!(?<$1>[^/]+)!g) {
    $handler = sub($req, $env) {
      $route->($req, $env, %+);
    };
  } else {
    $handler = $route;
  }
  push(@Routes, ['POST', $repath, $handler]);
}

sub forward($req, $env, $path, $params=undef) {
  my $fullPath;
  if ($params) {
    if (ref $params) {
      $fullPath = $path . '?' . build_urlencoded(%$params);
    } else {
      $fullPath = "$path?$params";
    }
  } else {
    $fullPath = $path;
  }
  $req->send_response(301, ['Location' => $fullPath], '');
}

sub template($req, $env, $template, $params=undef) {
  my $inner_content = SimpleMed::Template::template($template, $params);
  my $content = SimpleMed::Template::template('layouts/main', { content => $inner_content });
  $content = encode_utf8($content);
  $req->send_response(200, ['Content-Type' => 'text/html; charset=utf-8'], $content);
}

sub redirect($req, $env, $path, $params=undef) {
  my $fullPath;
  if ($params) {
    $fullPath = $path . '?' . build_urlencoded(%$params);
  } else {
    $fullPath = $path;
  }
  $req->send_response(303, ['Location' => $fullPath]);
}

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

sub req_login($route) {
  return sub {
    $route->(@_);
  };
}

get '/' => req_login sub($req, $env) {
  forward($req, $env, '/people');
};

get '/info' => req_login sub($req, $env) {
  template($req, $env, 'info');
};

sub param {
  die;
}

sub session {
  die;
}

get '/login' => sub($req, $env) {
  p($env);
  template($req, $env, 'login', { error => '', destination => param('destination') || '/' });
};

post '/login' => sub($req, $env) {
  use Data::Printer;
  p($env);
  die 500;
  my $username = param('username');
  my $password = param('password');

  my ($user, $login_error);
  try {
    $user = SimpleMed::Core::User::login($username, $password);
  } catch {
    $login_error = "$_->{code}: $_->{message}";
  };

  return template($req, $env, 'login', { banner => { type => 'notification', message => $login_error }, destination => param('destination') || '/', username => $username }) if $login_error;

  session( $_ => $user->{$_} ) foreach keys %$user;

  redirect($req, $env, param('destination') || '/');
};

get '/people' => req_login sub($req, $env) {
  template($req, $env, 'people', { people => [SimpleMed::Core::Person::get()] });
};

get '/people/new' => req_login sub($req, $env) {
  my $result = {
    person_id => 'new',
    time_zone => 'America/Los_Angeles'
   };
  template($req, $env, 'editPerson/details', $result);
};

get '/people/:id' => req_login sub($req, $env) {
  my $id = param('id');
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    die { code => 404, message => 'Person does not exist' };
  }
  template($req, $env, 'person', $result);
};

get '/people/:id/editDetails' => req_login sub($req, $env) {
  my $id = param('id');
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    die { code => 404, message => 'Person does not exist' };
  }
  template($req, $env, 'editPerson/details', $result);
};

sub uparam {
  return param(@_) || undef;
}

sub read_params_flat {
  return { map { $_ => uparam($_) } @_ };
}

my @detail_keys = qw(first_name middle_name last_name gender birth_date time_zone);

post '/people/new' => req_login sub($req, $env) {
  my ($new, $final);
  $new = read_params_flat @detail_keys;
  $final = SimpleMed::Core::Person::create(database(), $new);
  redirect($req, $env, '/people/' . $final->{person_id});
};

post '/people/:id/editDetails' => req_login sub($req, $env) {
  my $id = param('id');
  my ($original, $new, $final);
  $new = read_params_flat @detail_keys;
  $original = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $original) {
    die { code => 404, message => 'Person does not exist' };
  }
  my @d = diff($original, $new, @detail_keys);
  if (@d) {
    $final = SimpleMed::Core::Person::update(database(), $id, $new, @d);
  } else {
    $final = $original;
  }
  redirect($req, $env, '/people/' . $final->{person_id});
};

get '/people/:id/editAddresses' => req_login sub($req, $env) {
  my $id = param('id');
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    die { code => 404, message => 'Person does not exist' };
  }
  template($req, $env, 'editPerson/addresses', $result);
};

get '/people/:id/editPhones' => req_login sub($req, $env) {
  my $id = param('id');
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    die { code => 404, message => 'Person does not exist' };
  }
  template($req, $env, 'editPerson/phones', $result);
};

get '/people/:id/editEmails' => req_login sub($req, $env) {
  my $id = param('id');
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    die { code => 404, message => 'Person does not exist' };
  }
  template($req, $env, 'editPerson/emails', $result);
};

1;
