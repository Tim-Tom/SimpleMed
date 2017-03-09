package SimpleMed::Routing;

use v5.24;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Carp;

use WWW::Form::UrlEncoded qw(build_urlencoded);
use Unicode::UTF8 qw(encode_utf8);

use Try::Tiny;

use SimpleMed::Template;
use SimpleMed::Logger qw(:methods);
use SimpleMed::Error;

use Exporter qw(import);

our %EXPORT_TAGS = (
  methods => [qw(get post put check_session req_login)],
  responses => [qw(forward redirect template)],
  params => [qw(param uparam session)]
);

our @EXPORT_OK = map {@$_} values %EXPORT_TAGS;

our $Path_Prefix = '';
our %Routes;
our @Routes;
our $Routes;
our $Routes_Dirty;

sub prefix($path, $block) {
  local $Path_Prefix = $path;
  $block->();
}

sub add_handler($method, $path, $route) {
  $path = $Path_Prefix . $path;
  Debug(q^Adding Route^, { method => $method, path => $path });
  my @parts = map { quotemeta "/$_" } split('/', $path);
  # Get rid of empty leading slash
  shift @parts;
  push(@parts, quotemeta '/') if substr($path, -1, 1) eq '/';
  my @matches;
  my $map = \%Routes;
  foreach (@parts) {
    if (s!^\\\/\\:(\w+)$!\\\/(?<$1>[^/]+)!) {
      push(@matches, $1);
    }
    $map = ($map->{$_} //= {});
  }
  unless (exists $map->{''}) {
    push(@Routes, {});
    $map->{''} = $#Routes;
  }
  $map = $Routes[$map->{''}];
  if (exists $map->{$method}) {
    croak("$method:$path already exists");
  }
  ++$Routes_Dirty;
  $map->{$method} = (@matches ? sub($req) { $route->($req, @+{@matches}) } : $route);
}

sub get($path, $route) {
  add_handler('GET', $path, $route);
}

sub post($path, $route) {
  add_handler('POST', $path, $route);
}

sub put($path, $route) {
  add_handler('PUT', $path, $route);
}

sub handle_route_key($k, $v) {
  if ($k eq '') {
    return '\Z(?{'.$v.'})';
  } else {
    return "$k" . build_route_re($v);
  }
}

sub build_route_re($m) {
  my %map = %$m;
  my @keys = sort keys %map;
  if (@keys == 1) {
    my $key = $keys[0];
    return handle_route_key($keys[0], $map{$keys[0]});
  } else {
    return '(?:' . join('|', map { handle_route_key($_, $map{$_}) } @keys) . ')';
  }
}

sub build_routes() {
  Debug(q^Building Route Table^, { num_routes => scalar @Routes, routes_dirty => $Routes_Dirty });
  $Routes = build_route_re(\%Routes);
  use re 'eval';
  $Routes = qr/\A$Routes/s;
  $Routes_Dirty = 0;
  Debug(q^Done Building Route Table^);
}

sub route($req) {
  try {
    if ($Routes_Dirty) {
      Debug(q^Route table is dirty, rebuilding^);
      build_routes if $Routes_Dirty;
    }
    if ($req->path =~ $Routes) {
      my $routes = $Routes[$^R];
      if (!$routes) {
        die { code => 500, category => 'routing', message => "Routing Error" };
      }
      my $route = $routes->{$req->method};
      if ($route) {
        $route->($req);
      } else {
        SimpleMed::Error::Handle_Invalid_Method($req, sort keys %$routes);
      }
    } else {
      SimpleMed::Error::Handle_404($req);
    }
  } catch {
    SimpleMed::Error::Handle_Error($req, $_);
  }
}

sub forward($req, $path, $params=undef) {
  $path .= '?' . build_urlencoded(%$params) if $params;
  $req->send_response(301, ['Location' => $path, 'Content-Type' => 'text/plain; charset=utf-8'], "Located at: $path");
}

sub redirect($req, $path, $params=undef) {
  $path .= '?' . build_urlencoded(%$params) if $params;
  $req->send_response(303, ['Location' => $path, 'Content-Type' => 'text/plain; charset=utf-8'], "Response located at: $path");
}

sub template($req, $template, $params=undef) {
  my $inner_content = SimpleMed::Template::template($template, $params);
  my $content = SimpleMed::Template::template('layouts/main', { content => $inner_content });
  $content = encode_utf8($content);
  $req->send_response(200, ['Content-Type' => 'text/html; charset=utf-8'], $content);
}

sub param($req, @stuff) {
  die "This should be dying";
}

sub uparam {
  return param(@_) || undef;
}

sub session {
  die;
}

sub check_session($req) {
  # I don't really have security permissions in place right now. It's assumed everyone who
  # has a session is an admin at this point and has access to all the data.
  my $role = session($req, 'user_id');
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
