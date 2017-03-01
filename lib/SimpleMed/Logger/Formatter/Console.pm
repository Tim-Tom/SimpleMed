package SimpleMed::Logger::Formatter::Console;

use v5.24;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Data::Printer;

sub new($class, $args) {
  my %args = %$args;
  delete $args{class};
  return bless \%args, $class;
}

sub format_data($self, $data) {
  my %payload = %{$data->{payload}};
  if (%payload) {
    my $payload = np(%payload, %$self);
    $payload =~ s/{\n//;
    $payload =~ s/}\Z//m;
    return sprintf "%s: [%s] %s:\n%s", $data->{level}, $data->{message_id}, $data->{message}, $payload;
  } else {
    return sprintf "%s: [%s] %s\n", $data->{level}, $data->{message_id}, $data->{message};
  }
}

1;
