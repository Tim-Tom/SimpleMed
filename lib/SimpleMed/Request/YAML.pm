package SimpleMed::Request::YAML;

use strict;
use warnings;
use YAML::XS;

sub parse {
  my $content = shift;
  warn $content;
  return YAML::XS::Load($content);
}

1;
