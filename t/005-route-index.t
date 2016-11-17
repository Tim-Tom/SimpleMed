use strict;
use warnings;

use SimpleMed::Client;
use Test::More tests => 2;
use Plack::Test;
use HTTP::Request::Common;

my $app = SimpleMed::Client->to_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);
my $res  = $test->request( GET '/info' );

ok( $res->is_success, '[GET /info] successful' );
