package SimpleMed::DatabasePool;

use v5.24;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Const::Fast;

use AnyEvent;

use SimpleMed::Database;
use SimpleMed::Config qw(%Config);

const my $max_conn => $Config{database}{max_connections};
const my $reap_threshold => $Config{database}{connection_reap_threshold};

my @connections;
my @available_connections;
my @queued_acquisitions;

my $min_connection_available = 0;
my $connection_reaper;

package SimpleMed::AcquiredDatabaseConnection {
  sub new($class, $conn) {
    return bless(\$conn, $class);
  }

  sub execute {
    $_[0] = ${$_[0]};
    goto &SimpleMed::Database::execute;
  }

  sub DESTROY {
    push(@available_connections, $_[0]->$*);
    my $next_acquire = shift @queued_acquisitions;
    if ($next_acquire) {
      $next_acquire->send;
    }
  }
};

sub AcquireConnection {
  if (@available_connections) {
    my $connection_available = @available_connections;
    $min_connection_available = $connection_available if $connection_available < $min_connection_available;
    return SimpleMed::AcquiredDatabaseConnection->new(pop(@available_connections));
  } elsif (@connections < $max_conn) {
    my $conn = SimpleMed::Database->new();
    push(@connections, $conn);
    $min_connection_available = 0;
    if (!defined $connection_reaper) {
      $connection_reaper = AnyEvent->timer(after => $reap_threshold, repeat => $reap_threshold, cb => \&reap_connections);
    }
    return SimpleMed::AcquiredDatabaseConnection->new($conn);
  } else {
    my $cv = AnyEvent->condvar;
    push(@queued_acquisitions, $cv);
    $cv->wait;
    $min_connection_available = 0;
    return SimpleMed::AcquiredDatabaseConnection->new(pop(@available_connections));
  }
}

sub reap_connections {
  if ($min_connection_available > 0 && @available_connections) {
    my $reaped = shift @available_connections;
    my $i;
    for $i (0 .. $#connections) {
      last if ($reaped == $connections[$i]);
    }
    splice(@connections, $i, 1);
  }
  if (@connections == 0) {
    undef $connection_reaper;
  }
  $min_connection_available = @available_connections;
}

1;
