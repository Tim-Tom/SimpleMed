package SimpleMed::Template;

use v5.24;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Template::EmbeddedPerl;
use Unicode::UTF8 qw(decode_utf8);
use YAML::XS;

use AnyEvent;
use AnyEvent::IO;

use Try::Tiny;

use SimpleMed::Config qw(%Config);
use SimpleMed::Logger qw(:methods);

use Exporter qw(import);

our @EXPORT_OK = qw(get_template template);

my %templates;

sub read_template_pair($template_filename) {
  my $config_filename = $template_filename;
  $config_filename =~ s/\.\w+$/.yml/;
  try {
    my $template = read_template($template_filename)->recv;
    my $config = read_config($config_filename)->recv;
    return Template::EmbeddedPerl->new(filename => $template_filename, source => $template, config => $config, preamble => 'use strict;');
  } catch {
    if (ref) {
      die $_;
    } else {
      die { category => 'environment', message => "Unable to reify template: $_" };
    }
  }
}

sub read_template($filename) {
  my $template_read = AnyEvent->condvar;
  aio_stat $filename, sub($success=undef) {
    return $template_read->croak({ category => 'environment', message => "Unable to find template $filename" }) unless $success;
    my $length = -s _;
    aio_open $filename, AnyEvent::IO::O_RDONLY, 0, sub($in) {
      return $template_read->croak({ category => 'environment', message => "Unable to open template $filename for read: $!" }) unless $in;
      aio_read $in, $length, sub($data) {
        try {
          $in->close();
          $template_read->send(decode_utf8($data));
        } catch {
          $template_read->croak({ category => 'environment', message => "Unable to decodetemplate $filename: $_"});
        }
      };
    };
  };
  return $template_read;
}

sub read_config($filename) {
  my $config_read = AnyEvent->condvar;
  aio_stat $filename, sub($success=undef) {
    return $config_read->croak({ category => 'environment', message => "Unable to find template configuration $filename" }) unless $success;
    my $length = -s _;
    aio_open $filename, AnyEvent::IO::O_RDONLY, 0, sub($in) {
      return $config_read->croak({ category => 'environment', message => "Unable to open template configuration $filename for read: $!" }) unless $in;
      aio_read $in, $length, sub($data) {
        try {
          $in->close();
          my $config = YAML::XS::Load(decode_utf8($data));
          $config->{package} ||= 'SimpleMed::Views';
          $config_read->send($config);
        } catch {
          $config_read->croak({ category => 'environment', message => "Unable to parse template configuration $filename: $_" });
        };
      };
    };
  };
  return $config_read;
}

sub get_template($template) {
  unless ($Config{template}{caching} && $templates{$template}) {
    Debug(q^0010^, { template => $template });
    $templates{$template} = read_template_pair("$Config{server}{views}/$template.epl");
    Debug(q^0011^, { template => $template });
  } else {
    Debug(q^0012^, { template => $template });
  }
  return $templates{$template};
}

sub template($template, $data) {
  return get_template($template)->fill_in($data);
}

1;
