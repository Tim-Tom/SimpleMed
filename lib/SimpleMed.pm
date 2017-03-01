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
  my @possible_methods;
  # For now just build a simple awful regex based matcher. I wrote what could have been a
  # simple parser for this class of problem a couple years ago in C#. I could do so now,
  # but after I had written it, I was annoyed at having to reinvent the wheel. Essentially
  # all non-recursive regex engines could already do this if you could query their final
  # state because all we want is the state they ended on (which would tell us the
  # alternation branch(es) that matched). But for now since I'm just getting this thing
  # up, I'll just quickly transform the input into a regex and match the series of them
  # iteratively.
  foreach my $route (@SimpleMed::Routing::Routes) {
    my ($method, $regex, $handler) = @$route;
    my $correct_route = ($req->path =~ $regex);
    next unless $correct_route;
    if ($method ne $req->method) {
      push(@possible_methods, $method);
    } else {
      try {
        $handler->($req);
      } catch {
        SimpleMed::Error::Handle_Error($req, $_);
      };
      return;
    }
  }
  if (@possible_methods) {
    return SimpleMed::Error::Handle_Invalid_Method($req, @possible_methods);
  } else {
    return SimpleMed::Error::Handle_404($req);
  }
}

1;
