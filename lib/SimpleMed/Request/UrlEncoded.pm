package SimpleMed::Request::UrlEncoded;

use strict;
use warnings;
use WWW::Form::UrlEncoded qw(parse_urlencoded);
use List::Util qw(pairmap);

sub parse {
  my $content = shift;
  my $parsed = {};
  # As a special thing, we split keys on dashes and make them into arbitrarily complex
  # objects. Since I wasn't going to use dashes in keys otherwise, this doesn't reduce my
  # ability to just chain things through the process, but allows me to format the data
  # nicely.
  pairmap {
    my @path = split('-', $a);
    my $slot = \$parsed;
    for my $key (@path) {
      if ($key =~ /^\d+$/a) {
        $slot = \$$slot->[$key];
      } else {
        $slot = \$$slot->{$key};
      }
    }
    $$slot = ($b eq '') ? undef : $b;
  } parse_urlencoded($content);
  return $parsed;
}

1;
