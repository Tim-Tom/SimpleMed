#!/usr/bin/env perl
use v5.24;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use FindBin;
use lib "$FindBin::Bin/../lib";

use Feersum::Runner;

use SimpleMed;

my $runner = Feersum::Runner->new(
  listen => ['localhost:5000'],
  pre_fork => 0,
  quiet => 0,
 );

$runner->run(\&SimpleMed::Application);
