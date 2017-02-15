package SimpleMed;

use v5.24;

use strict;
use warnings;

use SimpleMed::Request;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Data::Printer;

my @routes;

sub Application($req) {
  my $env = SimpleMed::Request->new($req->env);
  p($req);
  p($req->env);
  if ($env->method eq 'POST') {
    p($env->content);
  }
  # For now just build a simple awful regex based matcher. I wrote what could have been a
  # simple parser for this class of problem a couple years ago in C#. I could do so now,
  # but after I had written it, I was annoyed at having to reinvent the wheel. Essentially
  # all non-recursive regex engines could already do this if you could query their final
  # state because all we want is the state they ended on (which would tell us the
  # alternation branch(es) that matched). But for now since I'm just getting this thing
  # up, I'll just quickly transform the input into a regex and match the series of them
  # iteratively.
  $req->send_response(
    200,
    [ 'Content-Type' => 'text/html' ],
    \<<'END_HTML'
<html>
<head>
  <title>Simple Form</title>
</head>
<body>
  <form method="post">
    <label for="username">Username</label><input type="text" name="username" />
    <label for="password">Password</label><input type="password" name="password" />
    <input type="submit" value="Login" />
  </form>
</body>
</html>
END_HTML
   );
}

1;
