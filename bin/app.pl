#!/usr/bin/env perl
use v5.24;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Cwd qw(realpath);

use FindBin;

use lib "$FindBin::Bin/../lib";

use Feersum::Runner;

use SimpleMed::Config;
BEGIN {

  my $root;

  $root = realpath("$FindBin::Bin/..");

  # This should have an argument form.
  my $config = "$root/config/$ENV{USER}.yml";
  if (!-f $config) {
    die "Configuration file at $config not found. Perhaps you need to clone it from $root/config/sample.yml";
  }
  SimpleMed::Config::create($config, $root);
}

use SimpleMed;


my $runner = Feersum::Runner->new(
  listen => ['localhost:5000'],
  pre_fork => 0,
  quiet => 0,
 );

$runner->run(\&SimpleMed::Application);