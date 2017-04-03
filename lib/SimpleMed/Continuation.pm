package SimpleMed::Continuation;

use v5.24;

use strict;
use warnings;

# If set, subcc will also adjust the stack trace to look as if it was called immediately
# instead of with whatever stack trace the callback was actually called in (probably a
# couple of generic library functions).
our $Include_Trace //= 0;
# If set, subcc will also take the time to save off the arguments of the stack trace along
# with the functions. To prevent messing with the lifecycle of variables, this trace will
# stringify the args.
our $Include_Trace_Args //= 0;
# If you're not worried about reference cycles, you can set this flag, which will store
# the arguments unmodified. This is slightly faster (though this whole process is pretty
# slow compared to just making a raw callback)
our $Include_Trace_Args_Real //= 0;

use Exporter qw(import);

our @EXPORT = qw(subcc);

# This is black magic that I have taken from Sub::Uplevel. Not sure why we need to define
# our own normal caller and do redirects instead of just assigning CORE::caller to it, but
# I'll trust that there is some reason that doesn't work. Because of the following, we
# need to be called as early in the module definition process as possible. Any module
# included before us will not have the caller swapped out (according to Sub::Uplevel).
BEGIN {
  if (not defined *CORE::GLOBAL::caller{CODE} ) {
    *CORE::GLOBAL::caller = \&_normal_caller;
  }
}

# We have to increase the height by 1 to skip over this function. Because caller has a
# different return depending on if you pass an argument to it, we can't just pass the
# result through, we have to manipulate the result.
sub _normal_caller : prototype(;$) {
  my $height = shift // 0;
  ++$height;
  my @caller = CORE::caller($height);
  if ( CORE::caller() eq 'DB' ) {
    # Oops, redo picking up @DB::args
    package DB;
    @caller = CORE::caller($height);
  }

  return if ! @caller;                  # empty
  return $caller[0] if ! wantarray;     # scalar context
  return @_ ? @caller : @caller[0..2];  # extra info or regular
}

use SimpleMed::Logger;

sub subcc : prototype(&) {
  my $f = shift;
  # Save off our global variables so they can be restored before the continuation resumes
  # operation.
  my $logger = $SimpleMed::Logger::Logger;
  my @stack;
  # So the fact that the function arguments is caller package based is really weird and
  # makes me have to duplicate code a bunch of times.
  if ($Include_Trace) {
    my $i = 0;
    if ($Include_Trace_Args) {
      package DB;
      while(my @results = caller(++$i)) {
        push(@stack, [[@results], [map { $Include_Trace_Args_Real ? $_ : "$_" } @DB::args]]);
      }
    } else {
      while(my @results = caller(++$i)) {
        push(@stack, [[@results], []]);
      }
    }
  }
  return sub {
    local $SimpleMed::Logger::Logger = $logger;
    if ($Include_Trace) {
      no warnings 'redefine';
      local *CORE::GLOBAL::caller = sub {
        my $height = $_[0] // 0;
        ++$height;
        # I could perhaps do this better by having up go exactly to $height and if our
        # inner check passes when up = height, making a meta callframe that is partially
        # our call and partially our callers. At the moment, we mention that we called the
        # sub-function instead of saying our caller did. Since this is made for callbacks,
        # I'm not sure it really matters since both are arbitrary stack frames. Plus if
        # I'm called straight from XS, I don't know that I have a parent frame.
        for (my $up = 1; $up < $height; ++$up) {
          my $test_caller = scalar CORE::caller($up);
          if ($test_caller && $test_caller eq __PACKAGE__) {
            my $entry = $stack[$height - $up - 1];
            return unless $entry;
            if (CORE::caller() eq 'DB') {
              @DB::args = @{$entry->[1]};
            }
            return $entry->[0][0] if !wantarray;
            return @_ ? @{$entry->[0]} : @{$entry->[0]}[0 .. 2];
          }
        }
        if (CORE::caller() eq 'DB') {
          package DB;
          return CORE::caller($height);
        } else {
          return CORE::caller($height);
        }
      };
      return $f->(@_);
    } else {
      return $f->(@_);
    }
  }
}

1;
