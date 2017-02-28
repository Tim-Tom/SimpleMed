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
  my ($id, $message);
  if ($data->{message_id} =~ /^\d+$/) {
    $id = $data->{message_id};
    $message = 'Not Yet Implemented';
  } else {
    $id = '00000';
    $message = $data->{message_id};
  }
  if (%payload) {
    my $payload = np(%payload, %$self);
    $payload =~ s/{\n//;
    $payload =~ s/}\Z//m;
    return sprintf "%s: [%s] %s:\n%s", $data->{level}, $id, $message, $payload;
  } else {
    return sprintf "%s: [%s] %s\n", $data->{level}, $id, $message;
  }
}

1;
