use strict;
use warnings;

use Test::More tests => 1;

use Test::Exception;

use SimpleMed::Continuation;

$SimpleMed::Continuation::Include_Trace = 1;
$SimpleMed::Continuation::Include_Trace_Args = 1;
$SimpleMed::Continuation::Include_Trace_Args_Real = 1;

sub trace {
  my @stack;
  my $i = 0;
  package DB;
  while(my ($package, $filename, $line, $subroutine) = caller($i++)) {
    push(@stack, { sub => $subroutine, args => [@DB::args]});
  }
  return \@stack;
}

sub call_rec_after {
  if (shift @_) {
    call_rec_after(@_);
  } else {
    trace();
  }
}

sub call_rec_before {
  my $level = shift;
  if ($level == 1) {
    return subcc \&call_rec_after;
  } else {
    return call_rec_before($level - 1, map { $_ + 1 } @_);
  }
}

sub expected_stack {
  my ($level, $bargs, $aargs) = @_;
  my @expected;
  my @bargs = @$bargs;
  for my $x (reverse 1 .. $level) {
    push(@expected, { args => [$x, @bargs], sub => "main::call_rec_before" });
    @bargs = map { $_ + 1; } @bargs;
  }
  my @aargs = @$aargs;
  while(@aargs) {
    push(@expected, { args => [@aargs], sub => 'main::call_rec_after' });
    shift @aargs;
  }
  push(@expected, { args => [], sub => 'main::call_rec_after' });
  push(@expected, { args => [], sub => 'main::trace' });
  return [reverse @expected];
}

sub check_stack {
  my ($level, $bargs, $aargs) = @_;
  my $result = call_rec_before($level, @$bargs)->(@$aargs);
  my $expected = expected_stack($level, $bargs, $aargs);
  while (pop(@$result)->{sub} ne 'main::check_stack') { };
  is_deeply($result, $expected, "call_rec: $level");
}

subtest recursive_stack => sub {
  plan tests => 10;
  for my $i (1 .. 10) {
    check_stack($i, [1,2,3], [qw(a b c)]);
  }
};
