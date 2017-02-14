use v5.24;

use strict;
use warnings;

use Socket;

use Feersum::Runner;
use Plack::Request;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Data::Printer;

sub app($req) {
  my $parsed_env = Plack::Request->new($req->env);
  p($req->env);
  p($parsed_env);
  p($parsed_env->body);
  p($parsed_env->address);
  p($parsed_env->base);
  p($parsed_env->body_parameters);
  p($parsed_env->content);
  p($parsed_env->content_encoding);
  p($parsed_env->content_length);
  p($parsed_env->content_type);
  p($parsed_env->cookies);
  p($parsed_env->headers);
  p($parsed_env->parameters);
  p($parsed_env->path);
  p($parsed_env->path_info);
  p($parsed_env->query_parameters);
  p($parsed_env->raw_body);
  p($parsed_env->request_body_parser);
  $req->send_response(
    200,
    [ 'Content-Type' => 'text/plain' ],
    \"Hello World"
   );
}

my $runner = Feersum::Runner->new(
  listen => ['localhost:3000'],
  pre_fork => 0,
  quiet => 0,
 );

$runner->run(\&app);
