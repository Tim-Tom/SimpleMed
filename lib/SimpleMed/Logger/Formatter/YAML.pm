package SimpleMed::Logger::Formatter::YAML;

use v5.24;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use YAML::XS;

sub new($class, $args) {
  while(my ($k, $v) = each $args->%*) {
    next if $k eq 'class';
    die "$k is not a supported argument to the YAML formatter";
  }
  return bless { }, $class;
}

sub format_data($self, $data) {
  return YAML::XS::Dump($data);
}

1;
