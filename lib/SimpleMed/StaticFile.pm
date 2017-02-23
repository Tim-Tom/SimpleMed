package SimpleMed::StaticFile;

use v5.24;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Const::Fast;

use Carp qw(croak);
use Plack::MIME;

use AnyEvent::IO;

use SimpleMed::Config qw(%Config);
use SimpleMed::Routing qw(get);

const my $buffer_size => $Config{static}{buffer_size};

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
  aio_stat $filename, sub($success=undef) {
    die 404 unless $success;
    my $length = -s _;
    aio_open $filename, AnyEvent::IO::O_RDONLY, 0, sub($in) {
      die 404 unless $in;
      if ($length < $buffer_size) {
        aio_read $in, $length, sub($data) {
          $in->close();
          $req->send_response(200, ['Content-Type' => $mime], $data);
        };
      } else {
        my $out = $req->start_streaming(200, ['Content-Type' => $mime]);
        read_block($in, $out);
      }
    }
  }
}

if ($Config{static}{enabled}) {
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
    get substr($filename, length 'public') => sub($req, $env) {
      get_static_file($req, $env, $mime, $filename);
    };
  }
}

1;
