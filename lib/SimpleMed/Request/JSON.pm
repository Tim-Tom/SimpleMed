package SimpleMed::Request::JSON;

use strict;
use warnings;
use JSON qw(from_json);

sub parse {
  my $content = shift;
  return from_json($content);
}

1;
