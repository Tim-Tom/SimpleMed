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
use SimpleMed::Routing qw(:methods :responses :params :vars);

get '/' => req_login sub() {
  forward('/people');
};

get '/info' => req_login sub() {
  template('info');
};

get '/login' => sub() {
  p($env);
  template('login', { error => '', destination => param('destination') || '/' });
};

post '/login' => sub() {
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

  return template('login', { banner => { type => 'notification', message => $login_error }, destination => param('destination') || '/', username => $username }) if $login_error;

  session( $_ => $user->{$_} ) foreach keys %$user;

  redirect(param('destination') || '/');
};

get '/people' => req_login sub() {
  template('people', { people => [SimpleMed::Core::Person::get()] });
};

get '/people/new' => req_login sub() {
  my $result = {
    person_id => 'new',
    time_zone => 'America/Los_Angeles'
   };
  template('editPerson/details', $result);
};

get '/people/:id' => req_login sub($id) {
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    die { code => 404, message => 'Person does not exist' };
  }
  template('person', $result);
};

get '/people/:id/editDetails' => req_login sub($id) {
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    die { code => 404, message => 'Person does not exist' };
  }
  template('editPerson/details', $result);
};

sub read_params_flat {
  return { map { $_ => uparam($_) } @_ };
}

my @detail_keys = qw(first_name middle_name last_name gender birth_date time_zone);

post '/people/new' => req_login sub() {
  my ($new, $final);
  $new = read_params_flat @detail_keys;
  $final = SimpleMed::Core::Person::create(database(), $new);
  redirect('/people/' . $final->{person_id});
};

post '/people/:id/editDetails' => req_login sub($id) {
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
  redirect('/people/' . $final->{person_id});
};

get '/people/:id/editAddresses' => req_login sub($id) {
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    die { code => 404, message => 'Person does not exist' };
  }
  template('editPerson/addresses', $result);
};

get '/people/:id/editPhones' => req_login sub($id) {
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    die { code => 404, message => 'Person does not exist' };
  }
  template('editPerson/phones', $result);
};

get '/people/:id/editEmails' => req_login sub($id) {
  my $result = SimpleMed::Core::Person::find_by_id($id);
  if (!defined $result) {
    die { code => 404, message => 'Person does not exist' };
  }
  template('editPerson/emails', $result);
};

1;
