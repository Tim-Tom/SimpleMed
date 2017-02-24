package SimpleMed::Request::UrlEncoded;

use strict;
use warnings;
use WWW::Form::UrlEncoded qw(parse_urlencoded);
use List::Util qw(pairmap);

sub parse {
  my $content = shift;
  my %parsed = pairmap { $a, ($b eq '') ? undef : $b } parse_urlencoded($content);
  return \%parsed;
}

1;
