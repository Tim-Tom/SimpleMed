use strict;
use warnings;

use Test::More tests => 1;

use Test::Exception;

use SimpleMed::Continuation;

$SimpleMed::Continuation::Include_Trace = 1;
$SimpleMed::Continuation::Include_Trace_Args = 1;
$SimpleMed::Continuation::Include_Trace_Args_Real = 1;

sub x1 {
  my @stuff = @_;
  return subcc {
    my @stack;
    my $i = 0;
    package DB;
    while(my ($package, $filename, $line, $subroutine) = caller($i++)) {
      push(@stack, { sub => $subroutine, args => [@DB::args]});
    }
    return \@stack;
  }
}

sub x2 {
  x1(map { $_ + 1; } @_);
}

sub x3 {
  x2(map { $_ + 1; } @_);
}

sub x4 {
  x3(map { $_ + 1; } @_);
}

sub x5 {
  x4(map { $_ + 1; } @_);
}

sub x6 {
  x5(map { $_ + 1; } @_);
}

use Data::Printer;
p(x6->(qw(a b c)));
