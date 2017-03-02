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
  my ($payload, $fmt, $request, $sequence);
  $fmt =  '[%d] %s: %s[%s] %s';
  if (%payload) {
    $payload = np(%payload, %$self);
    $payload =~ s/{\n//;
    $payload =~ s/}\Z//m;
    $fmt .= ":\n%s";
  } else {
    $fmt .= "\n";
  }
  $request = $data->{request_id} ? sprintf '[req:%d %0.3f] ', $data->{request_id}, $data->{elapsed} : '';
  return sprintf $fmt, $data->{sequence_id}, $data->{level}, $request, $data->{message_id}, $data->{message}, $payload;
}

1;
