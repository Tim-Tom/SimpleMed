package SimpleMed::Common;

use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(clone pick omit);

sub clone {
  my $hash = shift;
  return { map { $_ => $hash->{$_} } keys %$hash };
}

sub pick {
  my ($hash, @keys) = @_;
  return { map { $_ => $hash->{$_} } @keys };
}

sub omit {
  my ($hash, @keys) = @_;
  return { map { $_ => $hash->{$_} } grep { my $k = $_; !grep { $_  eq $k } @keys } keys %$hash };
}

1;
