#!/usr/bin/env perl

use strict;
use warnings;
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
