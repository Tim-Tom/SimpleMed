package SimpleMed::Storage;

use v5.24;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Sereal::Encoder;
use Sereal::Decoder;

use AnyEvent;
use AnyEvent::IO;

use File::Slurp qw(read_file);
use Try::Tiny;

use SimpleMed::Config qw(%Config);

our $instance;

sub new($class) {
  my $self = {
    encoder => Sereal::Encoder->new(),
    buffer => '',
    filename => $Config{database}{filename},
    handle => undef,
    write_open => 1,
    full_write => 0,
    enqueued => []
  };
  return bless $self, $class;
}

# This method is currently synchronous and uses a bunch of memory. I'm evaluating doing
# the pack myself, so don't want to spend to much time optimizing it.
sub load($self) {
  my $buffer =  read_file($self->{filename}, {binmode => ':raw' });
  my $decoder = Sereal::Decoder->new();
  my %frozen;
  my $first_read = 1;
  while($buffer) {
    my ($size, $content) = unpack('NA*', $buffer);
    die "Invalid read" if length($content) < $size;
    ($content, $buffer) = unpack("A${size}A*", $content);
    my %chunk = %{$decoder->decode($content)};
    if ($first_read) {
      %frozen = %chunk;
      $first_read = 0;
    } else {
      while(my ($type, $updates) = each %chunk) {
        @{$frozen{$type}}{keys %$updates} = values %$updates;
      }
    }
  }
  use Data::Printer;
  p(%frozen);
  my %thawed;
  
}

sub full_dump($self, $data) {
  # Todo: Test whether SRL_SNAPPY is actually useful for my compression of the full dump
  my $encoder = Sereal::Encoder->new({ compress => Sereal::Encoder::SRL_SNAPPY });
  my $out = $encoder->encode($data);
  # If there were previously unflushed writes, they no longer matter because we're doing a
  # full dump.
  $self->{buffer} = pack('NA*', length($out), $out);
  $self->{handle} = undef;
  $self->{full_write} = 1;
  return $self->_enqueue;
}

sub append($self, $data) {
  my $out = $self->{encoder}->encode($data);
  $self->{buffer} .= pack('NA*', length($out), $out);
  return $self->_enqueue;
}

sub _enqueue($self) {
  my $cv = AnyEvent->condvar;
  push(@{$self->{enqueued}}, $cv);
  $self->_write if $self->{write_open};
  return $cv;
}

sub _write($self) {
  $self->{write_open} = 0;
  my @notify = @{$self->{enqueued}};
  $self->{enqueued} = [];
  my $data = $self->{buffer};
  $self->{buffer} = '';
  if (!$self->{handle}) {
    my $cv = AnyEvent->condvar;
    my $type = AnyEvent::IO::O_CREAT | AnyEvent::IO::O_WRONLY;
    if ($self->{full_write}) {
      $type |= AnyEvent::IO::O_TRUNC;
      $self->{full_write} = 0;
    } else {
      $type |= AnyEvent::IO::O_APPEND;
    }
    aio_open $self->{filename}, $type, 0666, sub($fh=undef) {
      return $cv->croak({ category => 'environment', message => "Unable to open transactional log '$self->{filename}' for append: $!" }) unless $fh;
      return $cv->send($fh);
    };
    $cv->cb(sub {
      # Todo: Not handling errors yet.
      try {
        $self->{handle} = $cv->recv;
        $self->_write_data($data, @notify);
      } catch {
        foreach my $child (@notify) {
          $child->croak($_);
        }
      };
    });
  } else {
    $self->_write_data($data, @notify);
  }
}

sub _write_data($self, $data, @notify) {
  my $cv = AnyEvent->condvar;
  aio_write $self->{handle}, $data, sub($length=undef) {
    return $cv->croak({ category => 'environment', message => "Unable to write data to transactional log: $!" }) unless defined $length;
    return $cv->croak({ category => 'environment', message => "Wrote  log: $!" }) unless $length == length $data;
    return $cv->send();
  };
  $cv->cb(sub {
    try {
      $cv->recv;
      foreach my $child (@notify) {
        $child->send();
      };
    } catch {
      foreach my $child (@notify) {
        $child->croak($_);
      }
    };
    if (@{$self->{enqueued}}) {
      $self->_write;
    } else {
      $self->{write_open} = 1;
    }
  });
}

1;