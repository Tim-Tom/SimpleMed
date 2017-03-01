package SimpleMed::Logger::Formatter::JSON;

use v5.24;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use JSON;

sub new($class, $args) {
  my $encoder = JSON->new();
  while(my ($k, $v) = each $args->%*) {
    next if $k eq 'class';
    $encoder->$k($v);
  }
  return bless { encoder => $encoder }, $class;
}

sub format_data($self, $data) {
  return $self->{encoder}->encode($data);
}

1;
