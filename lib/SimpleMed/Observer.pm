package SimpleMed::Observer;

use strict;
use warnings;

use v5.24;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use SimpleMed::Logger qw(:methods);

sub undef_diff($a, $b) {
  return defined($a) ? (defined($b) ? undef : 1) : (defined($b) ? 1 : 0);
}

sub found_difference($self, $name, $before, $after) {
  # Plug into notifier.
  Debug(q^Attribute Changed^, { class => ref($self), instance => $self->id, attribute => $name, before => $before, after => $after });
}

sub observe_integer($name) {
  return sub($self, $after, $before=undef) {
    my $different = undef_diff($before, $after) // $before != $after;
    found_difference if $different;
  };
}

sub observe_real_abs($name, $threshold=0.05) {
  return sub($self, $after, $before=undef) {
    my $different = undef_diff($before, $after) // abs($before - $after) > $threshold;
    found_difference if $different;
  }
}

sub observe_real_rel($name, $ratio=1e-6) {
  return sub($self, $after, $before=undef) {
    my $different = undef_diff($before, $after) // abs($before - $after) > $before*$ratio;
    found_difference if $different;
  }
}

sub observe_string($name) {
  return sub($self, $after, $before=undef) {
    my $different = undef_diff($before, $after) // $before ne $after;
    found_difference if $different;
  };
}

1;
