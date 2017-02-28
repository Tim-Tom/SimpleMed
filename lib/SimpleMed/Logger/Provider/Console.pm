package SimpleMed::Logger::Provider::Console;

use v5.24;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use SimpleMed::Logger::Provider::File;

sub new($class, $args) {
  return bless {
    out => SimpleMed::Logger::Provider::File->new_from_fh(*STDOUT),
    err => SimpleMed::Logger::Provider::File->new_from_fh(*STDERR)
  }, $class;
}

sub send_data($self, $formatted, $data) {
  my $proxy;
  use Data::Printer;
  my %args = (
    formatted => $formatted,
    data => $data
  );
  p(%args);
  if ($data->{level} eq 'error' || $data->{level} eq 'warning' || $data->{level} eq 'fatal') {
    $proxy = $self->{err};
  } else {
    $proxy = $self->{out};
  }
  return $proxy->send_data($formatted, $data);
}

1;
