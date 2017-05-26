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
  template($req, 'people', { people => [SimpleMed::Core::People::get()] });
};

get '/people/new' => req_login sub($req) {
  my $result = SimpleMed::Core::Instance::Person->new(id => 0, first_name => '', last_name => '');
  template($req, 'editPerson/details', { person => $result });
};

get '/people/:id' => req_login sub($req, $id) {
  my $result = SimpleMed::Core::People::find_by_id($id);
  template($req, 'person', { person => $result });
};

get '/people/:id/editDetails' => req_login sub($req, $id) {
  my $result = SimpleMed::Core::People::find_by_id($id);
  template($req, 'editPerson/details', {person => $result });
};

sub read_params_flat($req, @args) {
  return { map { $_ => uparam($req, $_) } @args };
}

my @detail_keys = qw(first_name middle_name last_name gender birth_date time_zone);

post '/people/new' => req_login sub($req) {
  my ($new, $final);
  $new = $req->content;
  $final = SimpleMed::Core::People::create($new);
  redirect($req, '/people/' . $final->id);
};

post '/people/:id/editDetails' => req_login sub($req, $id) {
  my ($new, $final);
  $new = $req->content;
  $final = SimpleMed::Core::People::update($id, $new);
  redirect($req, '/people/' . $final->id);
};

get '/people/:id/editAddresses' => req_login sub($req, $id) {
  my $result = SimpleMed::Core::People::find_by_id($id);
  template($req, 'editPerson/addresses', { person => $result });
};

post '/people/:id/editAddresses' => req_login sub($req, $id) {
  my (@new, $final);
  @new = map { SimpleMed::Core::Instance::Person::Address->new($_); } sort {
    my $res = $a->{order} <=> $b->{order};
    die { code => 400, message => "Order $a->{order} was specified more than once" } if $res == 0;
    $res;
  } grep { $_->{address} } @{$req->content->{addresses}};
  $final = SimpleMed::Core::People::update($id, { addresses => \@new });
  redirect($req, '/people/' . $final->id);
};

get '/people/:id/editEmails' => req_login sub($req, $id) {
  my $result = SimpleMed::Core::People::find_by_id($id);
  template($req, 'editPerson/emails', { person => $result });
};

post '/people/:id/editEmails' => req_login sub($req, $id) {
  my (@new, $final);
  @new = sort {
    my $res = $a->{order} <=> $b->{order};
    die { code => 400, message => "Order $a->{order} was specified more than once" } if $res == 0;
    $res;
  } grep { $_->{email} } @{$req->content->{emails}};
  $final = SimpleMed::Core::People::update($id, { emails => \@new });
  redirect($req, '/people/' . $final->id);
};

get '/people/:id/editPhones' => req_login sub($req, $id) {
  my $result = SimpleMed::Core::People::find_by_id($id);
  template($req, 'editPerson/phones', { person => $result });
};

post '/people/:id/editPhones' => req_login sub($req, $id) {
  my (@new, $final);
  @new = sort {
    my $res = $a->{order} <=> $b->{order};
    die { code => 400, message => "Order $a->{order} was specified more than once" } if $res == 0;
    $res;
  } grep { $_->{number} } @{$req->content->{phones}};
  $final = SimpleMed::Core::People::update($id, { phones => \@new });
  redirect($req, '/people/' . $final->id);
};


1;
