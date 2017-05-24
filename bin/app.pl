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

use SimpleMed::Logger qw(:methods);

use SimpleMed;
use SimpleMed::Core;
use SimpleMed::Routing;
use SimpleMed::Views;
use SimpleMed::Continuation;

if (exists $SimpleMed::Config::Config{continuations} && $SimpleMed::Config::Config{continuations}{tracing}) {
  my $trace = $SimpleMed::Config::Config{continuations}{tracing};
  $SimpleMed::Continuation::Include_Trace = 1;
  if ($trace eq 'args') {
    $SimpleMed::Continuation::Include_Trace_Args = 1;
  } elsif ($trace eq 'args_real') {
    $SimpleMed::Continuation::Include_Trace_Args = 1;
    $SimpleMed::Continuation::Include_Trace_Args_Real = 1;
  }
}

SimpleMed::Core::LoadAll();

SimpleMed::Routing::build_routes;

my ($server, $port) = qw(localhost 5000);

my $runner = Feersum::Runner->new(
  listen => ["$server:$port"],
  pre_fork => 0,
  quiet => 0,
);

Info(q^0003^, { server => $server, port => $port });
$runner->run(\&SimpleMed::Application);
