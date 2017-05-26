package SimpleMed::API;

use v5.24;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Try::Tiny;

use JSON;
use YAML::XS;

use Unicode::UTF8 qw(encode_utf8);

use SimpleMed::Config qw(%Config);
use SimpleMed::Core;
use SimpleMed::Routing qw(:methods :params);

my $jc = $Config{serialization}{json};
my $json_encoder = JSON->new();
while(my ($k, $v) = each $jc->%*) {
  $json_encoder->$k($v);
}

my %handlers = (
  json => {
    respond => sub($req, $code, $content) {
      my $encoded = encode_utf8($json_encoder->encode($content));
      $req->send_response($code, ['Content-Type' => 'application/json'], $encoded);
    }
  },
  yaml => {
    respond => sub($req, $code, $content) {
      my $encoded = encode_utf8(YAML::XS::Dump($content));
      $req->send_response($code, ['Content-Type' => 'text/yaml'], $encoded);
    }
  },
);

for my $type (qw(json yaml)) {
  my $pkg = $handlers{$type};
  my $respond = $pkg->{respond};
  prefix "/api/$type" => sub {
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

    get '/people' => req_login sub($req) {
      $respond->($req, 200, [SimpleMed::Core::People::get()]);
    };
    prefix '/people' => sub {
      post '/new' => req_login sub($req, $id) {
        $respond->($req, 200, SimpleMed::Core::People::create($req->content));
      };
      get '/:id' => req_login sub($req, $id) {
        $respond->($req, 200, SimpleMed::Core::People::find_by_id($id));
      };
      put '/:id' => req_login sub($req, $id) {
        $respond->($req, 200, SimpleMed::Core::People::update($id, $req->content));
      };
    };

  };
}

1;
