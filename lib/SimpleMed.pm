package SimpleMed;

use v5.24;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Try::Tiny;

use EV;
use AnyEvent;
use AnyEvent::IO;
use AnyEvent::AIO;
use IO::AIO qw(aio_scandir);

use SimpleMed::Logger;
use SimpleMed::Request;
use SimpleMed::Routing;
use SimpleMed::StaticFile;
use SimpleMed::Client;
use SimpleMed::Error;

sub Application($feer_req) {
  # todo: wrap in try/catch
  my $req = SimpleMed::Request->new($feer_req);
  # Set the logger to the request so any stray logging statements underneath this call
  # will have the request id. Callbacks will have to pass the request manually, but it
  # allows for a little bit of magic logging to occur.
  local $SimpleMed::Logger::Logger = $req;
  SimpleMed::Routing::route($req);
}

1;
