package SimpleMed::Client;

use v5.24;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Try::Tiny;

use SimpleMed::Common qw(diff);
use SimpleMed::Core;
use SimpleMed::Routing qw(:methods :responses :params);

get '/' => req_login sub($req) {
  forward($req, '/people');
};

get '/info' => req_login sub($req) {
  template($req, 'info');
};

get '/login' => sub($req) {
  use Data::Printer;
  say "First request on login, does it work?";
  p($req);
  template($req, 'login', { error => '', destination => param('destination') || '/' });
};

post '/login' => sub($req) {
  die 500;
  my $username = param('username');
  my $password = param('password');

  my ($user, $login_error);
  try {
    $user = SimpleMed::Core::User::login($username, $password);
  } catch {
    $login_error = "$_->{code}: $_->{message}";
  };

  return template($req, 'login', { banner => { type => 'notification', message => $login_error }, destination => param('destination') || '/', username => $username }) if $login_error;

  session($req, $_ => $user->{$_} ) foreach keys %$user;

  redirect($req, param($req, 'destination') || '/');
};

get '/people' => req_login sub($req) {
  template($req, 'people', { people => [SimpleMed::Core::Person::get()] });
};

get '/people/new' => req_login sub($req) {
  my $result = {
    person_id => 'new',
    time_zone => 'America/Los_Angeles'
   };
  template($req, 'editPerson/details', $result);
};

get '/people/:id' => req_login sub($req, $id) {
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    die { code => 404, message => 'Person does not exist' };
  }
  template($req, 'person', $result);
};

get '/people/:id/editDetails' => req_login sub($req, $id) {
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    die { code => 404, message => 'Person does not exist' };
  }
  template($req, 'editPerson/details', $result);
};

sub read_params_flat($req, @args) {
  return { map { $_ => uparam($req, $_) } @args };
}

my @detail_keys = qw(first_name middle_name last_name gender birth_date time_zone);

post '/people/new' => req_login sub($req) {
  my ($new, $final);
  $new = $req->content;
  $final = SimpleMed::Core::Person::create(SimpleMed::DatabasePool::AcquireConnection(), $new);
  redirect($req, '/people/' . $final->{person_id});
};

post '/people/:id/editDetails' => req_login sub($req, $id) {
  my ($original, $new, $final);
  $new = $req->content;
  $original = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $original) {
    die { code => 404, message => 'Person does not exist' };
  }
  my @d = diff($original, $new, @detail_keys);
  if (@d) {
    $final = SimpleMed::Core::Person::update(SimpleMed::DatabasePool::AcquireConnection(), $id, $new, @d);
  } else {
    $final = $original;
  }
  redirect($req, '/people/' . $final->{person_id});
};

get '/people/:id/editAddresses' => req_login sub($req, $id) {
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    die { code => 404, message => 'Person does not exist' };
  }
  template($req, 'editPerson/addresses', $result);
};

post '/people/:id/editAddresses' => req_login sub($req, $id) {
  my ($original, $new, @final);
  my @new = sort {
    my $res = $a->{order} <=> $b->{order};
    die { code => 400, message => "Order $a->{order} was specified more than once" } if $res == 0;
    $res;
  } grep { $_->{address} } @{$req->content->{addresses}};
  $original = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $original) {
    die { code => 404, message => 'Person does not exist' };
  }
  my $final = SimpleMed::Core::Person::update_addresses(SimpleMed::DatabasePool::AcquireConnection(), $id, @new);
  redirect($req, '/people/' . $final->{person_id});
};

get '/people/:id/editEmails' => req_login sub($req, $id) {
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    die { code => 404, message => 'Person does not exist' };
  }
  template($req, 'editPerson/emails', $result);
};

post '/people/:id/editEmails' => req_login sub($req, $id) {
  my ($original, $new, @final);
  my @new = sort {
    my $res = $a->{order} <=> $b->{order};
    die { code => 400, message => "Order $a->{order} was specified more than once" } if $res == 0;
    $res;
  } grep { $_->{email} } @{$req->content->{emails}};
  $original = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $original) {
    die { code => 404, message => 'Person does not exist' };
  }
  my $final = SimpleMed::Core::Person::update_emails(SimpleMed::DatabasePool::AcquireConnection(), $id, @new);
  redirect($req, '/people/' . $final->{person_id});
};

get '/people/:id/editPhones' => req_login sub($req, $id) {
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    die { code => 404, message => 'Person does not exist' };
  }
  template($req, 'editPerson/phones', $result);
};

post '/people/:id/editPhones' => req_login sub($req, $id) {
  my ($original, $new, @final);
  my @new = sort {
    my $res = $a->{order} <=> $b->{order};
    die { code => 400, message => "Order $a->{order} was specified more than once" } if $res == 0;
    $res;
  } grep { $_->{number} } @{$req->content->{phones}};
  $original = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $original) {
    die { code => 404, message => 'Person does not exist' };
  }
  my $final = SimpleMed::Core::Person::update_phones(SimpleMed::DatabasePool::AcquireConnection(), $id, @new);
  redirect($req, '/people/' . $final->{person_id});
};


1;
