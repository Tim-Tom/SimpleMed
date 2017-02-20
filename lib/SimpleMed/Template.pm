package SimpleMed::Template;

use v5.24;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Text::Template;
use Unicode::UTF8 qw(decode_utf8);

use AnyEvent;
use AnyEvent::IO;

use SimpleMed::Config qw(%Config);

use Exporter qw(import);

our @EXPORT_OK = qw(get_template fill_in);

my %templates;

sub read_template($filename) {
  my $cv = AnyEvent->condvar;
  aio_stat $filename, sub($success=undef) {
    return $cv->croak({ category => 'environment', message => "Unable to find template $filename" }) unless $success;
    my $length = -s _;
    aio_open $filename, AnyEvent::IO::O_RDONLY, 0, sub($in) {
      return $cv->croak({ category => 'environment', message => "Unable to open template $filename for read: $!" }) unless $in;
      aio_read $in, $length, sub($data) {
        $in->close();
        $cv->send(Text::Template->new(TYPE => 'STRING', DELIMITERS => ['{%', '%}'], PREPEND => 'use SimpleMed::TemplateHelpers;', SOURCE => decode_utf8($data)));
      };
    };
  };
  my $result = eval {
    $cv->recv;
  };
  if ($@) {
    use Data::Printer;
    p($@);
  }
  return $result;
}

sub get_template($template) {
  unless ($Config{template}{caching} && $templates{$template}) {
    $templates{$template} = read_template("$Config{server}{views}/$template.tt");
  };
  return $templates{$template};
}

sub fill_in($template, $data) {
  return get_template($template)->fill_in(HASH => $data);
}

1;
