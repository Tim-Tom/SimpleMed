package SimpleMed::Request;

use v5.24;

use strict;
use warnings;

use parent qw(Plack::Request);
use Carp qw(croak);

use Encode qw(encode decode);

use SimpleMed::Request::UrlEncoded;
use SimpleMed::Request::JSON;
use SimpleMed::Request::YAML;

sub _parse_content_type {
  my $ct = lc shift;
  my $tspecials = '\s' . quotemeta '()<>@,;:\\"/[]?= ';
  if (my ($type, $subtype, $charset) = $ct =~ m!^([^$tspecials]+)/([^$tspecials]+)(?:\s*;\s*charset=(\S+))?!) {
    return ("$type/$subtype", $charset);
  } else {
    croak("Could not parse $ct");
  }
}



my %parsers = (
  'application/x-www-form-urlencoded' => ['iso-8859-1', \&SimpleMed::Request::UrlEncoded::parse],
  'application/json' => ['utf-8', \&SimpleMed::Request::JSON::parse],
  'application/yaml' => ['utf-8', \&SimpleMed::Request::YAML::parse],
  'text/yaml' => ['utf-8', \&SimpleMed::Request::YAML::parse],
);

@parsers{qw(application/x-yaml text/x-yaml)} = @parsers{qw(application/yaml text/yaml)};

sub _parse_content {
  my $self = shift;
  my $body;
  my $in = delete $self->env->{'psgi.input'};
  croak("Requested content of request with no body") unless $in;
  # At the moment, feersum does not support streaming request bodies. I don't particularly
  # like that, but until I want to support multi megabyte CSV upload, that's probably
  # fine. According to the docs, we won't be called until the request body has fully come
  # in and we always have a content_length.
  my $cl = $self->content_length;
  if ($cl) {
    $in->read($body, $cl);
    $in->close;
    $in = undef;
  } else {
    croak "Feersum broke API contract";
  }
  # Todo: Handle content encoding.
  my ($type, $charset) = _parse_content_type($self->content_type);
  my $parser = $parsers{$type};
  unless ($parser) {
    croak "Content type of " . $self->content_type . " is not supported.";
  }
  $charset ||= $parser->[0];
  $parser = $parser->[1];
  return $parser->(decode($charset, $body));
}


sub content {
  my $self = shift;
  $self->_parse_content;
}

sub uploads {
  croak "Unsupported for now, I think this one may live";
}

sub raw_body {
  croak "raw_body is not supported, please use content.";
}

sub _body_parameters {
  croak "body_parameters are not supported, please use content.";
}

sub _parse_request_body {
  croak "_parse_request_body is not supported.";
}
