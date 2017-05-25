package SimpleMed::Common;

use strict;
use warnings;

use Try::Tiny;

use Exporter qw(import);

use SimpleMed::Logger qw(:methods);

our @EXPORT_OK = qw(clone pick omit diff parse_date);

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

sub diff {
  my ($a, $b, @keys) = @_;
  my @d;
  for my $k (@keys) {
    no warnings 'uninitialized';
    push(@d, $k) if $a->{$k} ne $b->{$k};
  }
  return @d;
}

sub parse_date {
  my ($date_str, ) = @_;
  my ($year, $month, $day);
  if (($year, $month, $day) = $date_str =~ m!^(\d{4})[-/.](\d{2})[-/.](\d{2})$!a) {
    # Nothing to do
  } elsif (($month, $day, $year) = $date_str =~ m!^(\d{1,2})[-/.](\d{1,2})[-/.](\d{2,4})$!a) {
    if ($month <= 12 && $day > 12) {
      # Nothing to do
    } elsif ($day <= 12 && $month > 12) {
      # European date, switch
      ($month, $day) = ($day, $month);
    } else {
      # Ambiguous date
      Debug(q^0020^, { date => $date_str } );
    }
    if ($year < 25) {
      $year += 200;
      Debug(q^0021^, { date => $date_str, year => $year });
    } elsif ($year < 100) {
      $year += 100;
      Debug(q^0021^, { date => $date_str, year => $year });
    }
  } else {
    die { code => 400, summary => 'Input Validation Error', message => 'Cannot determine date format', input => $date_str };
  }
  if ($month == 0 || $month > 12) {
    die { code => 400, summary => 'Input Validation Error', message => 'Month must be between 1 and 12', input => $date_str };
  }
  my $date = Date::Simple::ymd($year, $month, $day);
  if (!defined $date) {
    die { code => 400, summary => 'Input Validation Error', message => 'Invalid date', input => $date_str, year => $year, month => $month, day => $day };
  }
  return $date;
}

1;
