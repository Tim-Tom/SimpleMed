package SimpleMed::Client;

use strict;
use warnings;

use Dancer2 appname => 'SimpleMed';

get '/' => sub {
  session('user') or redirect('/login');
};

get '/login' => sub {
  template 'login';
};

get '/info' => sub {
  template 'info';
};

true;
