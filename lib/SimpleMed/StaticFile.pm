package SimpleMed::StaticFile;

use v5.24;

use Const::Fast;

use strict;
use warnings;

use Carp qw(croak);
use Plack::MIME;

use AnyEvent::IO;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

our @Routes;

const my $buffer_size => 16 * 1024;

sub read_block($in, $out) {
  aio_read $in, $buffer_size, sub($data) {
    if (length($data) > 0) {
      $out->write($data);
    }
    if (length($data) == $buffer_size) {
      read_block($in, $out);
    } else {
      $in->close();
      $out->close();
    }
  };
}

sub get_static_file($req, $env, $mime, $filename) {
  aio_stat $filename, sub {
    my $success = shift;
    die 404 unless $success;
    my $length = -s _;
    aio_open $filename, AnyEvent::IO::O_RDONLY, 0, sub($in) {
      die 404 unless $in;
      if ($length < $buffer_size) {
        aio_read $in, $length, sub($data) {
          $in->close();
          $req->send_response(200, ['Content-Type' => $mime, 'Content-Length' => $length], $data);
        };
      } else {
        my $out = $req->start_streaming(200, ['Content-Type' => $mime]);
        read_block($in, $out);
      }
    }
  }
}

{
  my @dirs = ('public');
  my @files;

  while(my $dirname = shift(@dirs)) {
    opendir(my $dir, $dirname) or die "Unable to open '$dirname' for read: $!";
    while(readdir $dir) {
      next if /^\.\.?$/;
      my $path = "$dirname/$_";
      if (-d $path) {
        push(@dirs, $path);
      } else {
        push(@files, $path);
      }
    }
  }

  foreach my $filename (@files) {
    my $mime = Plack::MIME->mime_type($filename);
    say "mime type of $filename is $mime";
    my $fileRegex = quotemeta substr($filename, length 'public');
    $fileRegex = qr/^$fileRegex$/;
    push(@Routes, ['GET', $fileRegex, sub($req, $env) { get_static_file($req, $env, $mime, $filename) }]);
  }
}

1;
