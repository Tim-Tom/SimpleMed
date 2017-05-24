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
use Promises qw(deferred collect);

use Try::Tiny;

use SimpleMed::Config qw(%Config);
use SimpleMed::Logger qw(:methods);

use SimpleMed::Continuation;

use Exporter qw(import);

our @EXPORT_OK = qw(get_template template get_template_strict template_strict);

my %templates;

sub read_template_pair($template_filename) {
  my $config_filename = $template_filename;
  $config_filename =~ s/\.\w+$/.yml/;
  return collect (
    read_template($template_filename),
    read_config($config_filename)
   )->then(subcc {
     my ($template, $config) = map { $_->[0] } @_;
     Template::EmbeddedPerl->new(filename => $template_filename, source => $template, config => $config, preamble => 'use strict;');
   });
}

sub read_template($filename) {
  my $template_read = deferred;
  aio_stat $filename, sub($success=undef) {
    return $template_read->reject({ category => 'environment', message => "Unable to find template $filename" }) unless $success;
    my $length = -s _;
    aio_open $filename, AnyEvent::IO::O_RDONLY, 0, sub($in) {
      return $template_read->reject({ category => 'environment', message => "Unable to open template $filename for read: $!" }) unless $in;
      aio_read $in, $length, sub($data) {
        try {
          $in->close();
          $template_read->resolve(decode_utf8($data));
        } catch {
          $template_read->reject({ category => 'environment', message => "Unable to decode template $filename: $_"});
        }
      };
    };
  };
  return $template_read;
}

sub read_config($filename) {
  my $config_read = deferred;
  aio_stat $filename, sub($success=undef) {
    return $config_read->reject({ category => 'environment', message => "Unable to find template configuration $filename" }) unless $success;
    my $length = -s _;
    aio_open $filename, AnyEvent::IO::O_RDONLY, 0, sub($in) {
      return $config_read->reject({ category => 'environment', message => "Unable to open template configuration $filename for read: $!" }) unless $in;
      aio_read $in, $length, sub($data) {
        try {
          $in->close();
          my $config = YAML::XS::Load(decode_utf8($data));
          $config->{package} ||= 'SimpleMed::Views';
          if ($config->{children} && @{$config->children}) {
            collect(map { get_template($_) } @{$config->{children}})->then(sub { $config_read->resolve($config) });
          } else {
            $config_read->resolve($config);
          }
        } catch {
          $config_read->reject({ category => 'environment', message => "Unable to parse template configuration $filename: $_" });
        };
      };
    };
  };
  return $config_read;
}

sub get_template($template) {
  my $d = deferred;
  unless ($Config{template}{caching} && $templates{$template}) {
    Debug(q^0010^, { template => $template });
    $d = $templates{$template} = read_template_pair("$Config{server}{views}/$template.epl")->then(subcc {
     Debug(q^0011^, { template => $template });
     return @_;
   });
  } else {
    $d->resolve($templates{$template});
    Debug(q^0012^, { template => $template });
  }
  return $d;
}

sub template($template, $data) {
  return get_template($template)->then(subcc sub($t) { $t->fill_in($data) });
}

sub get_template_strict($template) {
  if (!exists $templates{$template} || $templates{$template}->is_in_progress) {
    die "Template $template has not been realized.";
  }
  if ($templates{$template}->is_rejected) {
    die ${ $templates{$template}->result }[0];
  }
  return ${ $templates{$template}->result }[0];
}

sub template_strict($template, $data) {
  return get_template_strict($template)->fill_in($data);
}

1;
