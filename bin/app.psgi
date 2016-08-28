#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use SimpleMed::Client;
use SimpleMed::API;

use Plack::Builder;
use Dancer2;

builder {
  enable 'Deflater';
  mount '/' => SimpleMed::Client->to_app;
  mount '/api' => SimpleMed::API->to_app;
};
