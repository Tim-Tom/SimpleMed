package SimpleMed::Error;

use v5.24;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use JSON;
use YAML::XS;

use SimpleMed::Config qw(%Config);
use SimpleMed::Template;

use Unicode::UTF8 qw(encode_utf8);

my %default_summary = (
  400 => 'Bad Request',
  401 => 'Unauthorized',
  402 => 'Payment Required',
  403 => 'Forbidden',
  404 => 'Not Found',
  405 => 'Method Not Allowed',
  406 => 'Not Acceptable',
  407 => 'Proxy Authentication Required',
  408 => 'Request Time-out',
  409 => 'Conflict',
  410 => 'Gone',
  411 => 'Length Required',
  412 => 'Precondition Failed',
  413 => 'Payload Too Large',
  414 => 'URI Too Long',
  415 => 'Unsupported Media Type',
  416 => 'Range Not Satisfiable',
  417 => 'Expectation Failed',
  421 => 'Misdirected Request',
  422 => 'Unprocessable Entity',
  423 => 'Locked',
  424 => 'Failed Dependency',
  426 => 'Upgrade Required',
  428 => 'Precondition Required',
  429 => 'Too Many Requests',
  431 => 'Request Header Fields Too Large',
  451 => 'Unavailable For Legal Reasons',
  500 => 'Internal Server Error',
  501 => 'Not Implemented',
  502 => 'Bad Gateway',
  503 => 'Service Unavailable',
  504 => 'Gateway Time-out',
  505 => 'HTTP Version Not Supported',
  506 => 'Variant Also Negotiates',
  507 => 'Insufficient Storage',
  508 => 'Loop Detected',
  510 => 'Not Extended',
  511 => 'Network Authentication Required',
);

my $jc = $Config{serialization}{json};
my $json_encoder = JSON->new();
while(my ($k, $v) = each $jc->%*) {
  $json_encoder->$k($v);
}

sub Handle_Error($req, $error) {
  my %error;
  my $errType = ref($error);
  if ($errType) {
    if ($errType eq 'HASH') {
      %error = %{$error};
    } else {
      warn "Unable to handle warning of type $errType";
      %error = (
        code => 500,
        message => "An unknown error occured."
      );
    }
  } elsif ($error =~ /^\d+$/) {
    %error = (
      code => $error,
    );
  } else {
    %error = (
      message => $error
    );
  }
  $error{code} ||= 500;
  $error{summary} ||= $default_summary{$error{code}};
  $req->error(q^0006^, { error => \%error });
  if ($req->path =~ m!^/api/json!) {
    send_error_json($req, \%error);
  } elsif ($req->path =~ m!^/api/yaml!) {
    send_error_yaml($req, \%error);
  } else {
    send_error_template($req, \%error);
  }
}

sub Handle_404($req) {
  return Handle_Error($req, { code => 404, message => "The resource requested at ".($req->path)." does not exist." });
}

sub Handle_Invalid_Method($req, @possible_methods) {
  my $path = $req->path;
  my $method = $req->method;
  my $message = "$method is not a valid http method for $path.";
  return Handle_Error($req, { code => 405, possible => \@possible_methods, message => $message });
}

sub send_error_template($req, $error) {
  my $content = encode_utf8(SimpleMed::Template::template('layouts/error', $error));
  $req->send_response($error->{code}, ['Content-Type' => 'text/html; charset=utf-8'], $content);
}

sub send_error_yaml($req, $error) {
  my $content = encode_utf8(YAML::XS::Dump($error));
  $req->send_response($error->{code}, ['Content-Type' => 'text/yaml'], $content);
}

sub send_error_json($req, $error) {
  my $content = encode_utf8($json_encoder->encode($error));
  $req->send_response($error->{code}, ['Content-Type' => 'application/json'], $content);
}

1;
