package SimpleMed::Request::UrlEncoded;

use strict;
use warnings;
use WWW::Form::UrlEncoded qw(parse_urlencoded);

sub parse {
  my $content = shift;
  my %parsed = parse_urlencoded($content);
  return \%parsed;
}

1;
