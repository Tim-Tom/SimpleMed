package SimpleMed::Routing;

use v5.24;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use WWW::Form::UrlEncoded qw(build_urlencoded);
use Unicode::UTF8 qw(encode_utf8);

use SimpleMed::Template;

use Exporter qw(import);

our %EXPORT_TAGS = (
  methods => [qw(get post put check_session req_login)],
  responses => [qw(forward redirect template)],
  params => [qw(param uparam session)],
  vars => [qw($req $env)]
);

our @EXPORT_OK = map {@$_} values %EXPORT_TAGS;

package SimpleMed::Routing::Failure {
  no strict;
  no warnings;
  use Carp qw(croak);
  sub new($class, $name) {
    return bless(\$name, $class);
  }
  sub AUTOLOAD {
    my $name = shift;
    my $method = substr($AUTOLOAD, rindex($AUTOLOAD, ':') + 1);
    croak "Attempted to use $$name as an instantiated object by calling '$method' on it outside of a request.";
  }
  sub DESTROY { }
};

our @Routes;
our ($req, $env) = map { SimpleMed::Routing::Failure->new($_); } qw($req $env);

sub make_handler($path, $route) {
  my $repath = quotemeta $path;
  my $handler;
  my @matches;
  if ($repath =~ s!\\:(\w+)!push(@matches, $1); "(?<$1>[^/]+)"!ge) {
    $handler = sub($r, $e) {
      local $req = $r;
      local $env = $e;
      $route->(@+{@matches});
    };
  } else {
    $handler = sub($r, $e) {
      local $req = $r;
      local $env = $e;
      $route->();
    }
  }
  $repath = qr/^$repath$/;
  return ($repath, $handler);
}

sub get($path, $route) {
  push(@Routes, ['GET', make_handler($path, $route)]);
}

sub post($path, $route) {
  push(@Routes, ['POST', make_handler($path, $route)]);
}

sub put($path, $route) {
  push(@Routes, ['PUT', make_handler($path, $route)]);
}

sub forward($path, $params=undef) {
  my $fullPath;
  $path .= '?' . build_urlencoded(%$params) if $params;
  $req->send_response(301, ['Location' => $fullPath], '');
}

sub redirect($path, $params=undef) {
  my $fullPath;
  $path .= '?' . build_urlencoded(%$params) if $params;
  $req->send_response(303, ['Location' => $fullPath]);
}

sub template($template, $params=undef) {
  my $inner_content = SimpleMed::Template::template($template, $params);
  my $content = SimpleMed::Template::template('layouts/main', { content => $inner_content });
  $content = encode_utf8($content);
  $req->send_response(200, ['Content-Type' => 'text/html; charset=utf-8'], $content);
}

sub param {
  p($env);
  die;
}

sub uparam {
  return param(@_) || undef;
}

sub session {
  die;
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
