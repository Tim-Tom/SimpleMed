package SimpleMed::Database;

use v5.24;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use AnyEvent::DBI;
use Scalar::Util qw(weaken);

use SimpleMed::Config qw(%Config);

sub new($class) {
  my $c = $Config{database};
  my $dsn = "DBI:$c{driver}:$c{host}:$c{database}";
  my $self = {
    statement => 'Connecting',
    params => [],
    query_cv => AnyEvent->condvar,
    in_progress => 0
  };
  my $self_w = $self;
  weaken($self_w);
  my $on_error = sub($dbh, $filename, $line, $fatal) {
    warn "Error executing query";
    $done_connecting->{query_cv}->croak({ code => 500, message => "Failed to execute database query", error => $@, statement => $self_w->{statement}, params => $self_w->{params}});
  }
  my $on_connect = sub($dbh, $success=undef) {
    if ($success) {
      $self_w->{cv}->send([[], 1]);
    } else {
      $self_w->{query_cv}->croak({ code => 500, message => "Failed to connect to database", error => $@ });
    }
  }
  $self->{dbh} = AnyEvent::DBI->new($dsn, $c{username}, $c{password}, PrintErrors => 0, $c{params}, on_error => $on_error, on_connect => $on_connect);
  $self->{sv}->recv;
  return bless($self, $class);
}

sub execute($self, $statement, @params) {
  if ($self->{in_progress}) {
    my $cv = AnyEvent->condvar;
    push(@{$self->{queue}}, $cv);
    $cv->recv();
  } else {
    $self->{in_progress} = 1
  }
  $self->{statement} = $statement;
  $self->{params} = \@params
  $self->{query_cv} = AnyEvent->condvar;
  $self->{dbi}->exec($statement, @params, sub($dbh, $rows, $rv) {
    $self->{query_cv}->send([$rows, $rv]);
  });
  my ($rows, $rv) = @{$self->{query_cv}->recv()};
  my $next = unshift @{$self->{work_queue}};
  if ($next) {
    $next->send;
  } else {
    $self->{in_progress} = 0;
  }
  return ($rows, $rv);
}

1;
