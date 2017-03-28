package SimpleMed::Observer;

use strict;
use warnings;

use v5.24;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use List::Util qw(any);

use SimpleMed::Logger qw(:methods);

use Exporter qw(import);

our %EXPORT_TAGS = (
  compare => [qw(compare_undef compare_integer compare_string compare_real_abs compare_real_rel compare_array)],
  observe => [qw(observe_variable observe_integer observe_string observe_real_abs observe_real_rel observe_array)]
);

our @EXPORT_OK = map {@$_} values %EXPORT_TAGS;

sub compare_undef($a, $b) {
  return defined($a) ? (defined($b) ? undef : 1) : (defined($b) ? 1 : 0);
}

sub compare_integer($a, $b) {
  return compare_undef($a, $b) // $a != $b;
}

sub compare_real_abs($a, $b, $t) {
  return compare_undef($a, $b) // abs($a - $b) > $t;
}

sub compare_real_rel($a, $b, $r) {
  my $diff = compare_undef($a, $b);
  return $diff if defined $diff;
  my $m = abs($a) > abs($b) ? abs($a) : abs($b);
  return abs($a - $b) > $m*$r;
}

sub compare_string($a, $b) {
  return compare_undef($a, $b) // $a ne $b;
}

sub compare_array($a, $b, $cmp) {
  my $diff = compare_undef($a, $b);
  return $diff if defined $diff;
  my @a = @$a;
  my @b = @$b;
  return 1 if @a != @b;
  return any { $cmp->($a[$_], $b[$_]) } 0 .. $#a;
}

sub found_difference($self, $name, $before, $after) {
  # Plug into notifier.
  Debug(q^Attribute Changed^, { class => ref($self), instance => $self->id, attribute => $name, before => $before, after => $after });
}

sub observe_variable($name, $comparer) {
  return sub($self, $after, $before=undef) {
    found_difference($self, $name, $before, $after) if $comparer->($before, $after);
  }
}

sub observe_integer($name) {
  return observe_variable($name, \&compare_integer);
}

sub observe_real_abs($name, $threshold=0.05) {
  return observe_variable($name, sub { push(@_, $threshold); goto &compare_real_abs });
}

sub observe_real_rel($name, $ratio=1e-6) {
  return observe_variable($name, sub { push(@_, $ratio); goto &compare_real_rel });
}

sub observe_string($name) {
  return observe_variable($name, \&compare_string);
}

sub observe_array($name, $comparer) {
  return observe_variable($name, sub { push(@_, $comparer); goto &compare_array });
}

1;
