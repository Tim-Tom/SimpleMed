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
  params => [qw(param uparam session)]
);

our @EXPORT_OK = map {@$_} values %EXPORT_TAGS;

our @Routes;

sub make_handler($path, $route) {
  my $repath = quotemeta $path;
  my $handler;
  my @matches;
  if ($repath =~ s!\\:(\w+)!push(@matches, $1); "(?<$1>[^/]+)"!ge) {
    $handler = sub($req, $env) {
      $route->($req, $env, @+{@matches});
    };
  } else {
    $handler = $route;
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

sub forward($req, $env, $path, $params=undef) {
  $path .= '?' . build_urlencoded(%$params) if $params;
  $req->send_response(301, ['Location' => $path, 'Connection' => 'Close'], '');
}

sub redirect($req, $env, $path, $params=undef) {
  $path .= '?' . build_urlencoded(%$params) if $params;
  $req->send_response(303, ['Location' => $path, 'Connection' => 'Close'], '');
}

sub template($req, $env, $template, $params=undef) {
  my $inner_content = SimpleMed::Template::template($template, $params);
  my $content = SimpleMed::Template::template('layouts/main', { content => $inner_content });
  $content = encode_utf8($content);
  $req->send_response(200, ['Content-Type' => 'text/html; charset=utf-8'], $content);
}

sub param($req, $env, @stuff) {
  die "This should be dying";
}

sub uparam {
  return param(@_) || undef;
}

sub session {
  die;
}

sub check_session($req, $env) {
  # I don't really have security permissions in place right now. It's assumed everyone who
  # has a session is an admin at this point and has access to all the data.
  my $role = session($req, $env, 'user_id');
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

1;
