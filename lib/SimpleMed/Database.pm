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
use SimpleMed::Logger qw(:methods);

sub new($class) {
  my %c = $Config{database}->%*;
  my $dsn = "DBI:$c{driver}:host=$c{host};db=$c{database}";
  my $self = {
    statement => 'Connecting',
    params => [],
    query_cv => AnyEvent->condvar,
    in_progress => 0
  };
  my $self_w = $self;
  weaken($self_w);
  my $on_error = sub($dbh, $filename, $line, $fatal) {
    $self_w->{query_cv}->croak({ code => 500, message => "Failed to execute database query", error => $@, statement => $self_w->{statement}, params => $self_w->{params}});
  };
  my $on_connect = sub($dbh, $success=undef) {
    if ($success) {
      $self_w->{query_cv}->send([[], 1]);
    } else {
      $self_w->{query_cv}->croak({ code => 500, message => "Failed to connect to database", error => $@ });
    }
  };
  Debug(q^0007^, { connection => $dsn, username => $c{username}, password => ($c{password} ? '(with password)' : '(no password)'), instance => "SimpleMed::Database=$self" });
  $self->{dbh} = AnyEvent::DBI->new($dsn, $c{username}, $c{password}, PrintError => 0, $c{params}->%*, on_error => $on_error, on_connect => $on_connect);
  $self->{query_cv}->recv;
  return bless($self, $class);
}

sub DESTROY {
  my $self = shift;
  Debug(q^0008^, { instance => "$self" });
}

sub execute($self, $statement, @params) {
  if ($self->{in_progress}) {
    my $cv = AnyEvent->condvar;
    push(@{$self->{queue}}, $cv);
    $cv->recv();
  } else {
    $self->{in_progress} = 1
  }
  Debug(q^0009^, { statement => $statement, params => \@params });
  $self->{statement} = $statement;
  $self->{params} = \@params;
  $self->{query_cv} = AnyEvent->condvar;
  $self->{dbh}->exec($statement, @params, sub($dbh, $rows=undef, $rv=undef) {
    $self->{query_cv}->send([$rows, $rv]);
  });
  my ($rows, $rv) = @{$self->{query_cv}->recv()};
  my $next = shift(@{$self->{work_queue}});
  if ($next) {
    $next->send;
  } else {
    $self->{in_progress} = 0;
  }
  if (wantarray) {
    return @$rows;
  } elsif (defined wantarray) {
    return $rv;
  }
}

1;
