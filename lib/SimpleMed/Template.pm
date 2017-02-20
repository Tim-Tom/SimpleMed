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

my %templates;

sub read_template($filename) {
  my $cv = AnyEvent->condvar;
  aio_stat $filename, sub {
    my $success = shift;
    return $cv->croak({ category => 'environment', message => "Unable to find template $filename" }) unless $success;
    my $length = -s _;
    aio_open $filename, AnyEvent::IO::O_RDONLY, 0, sub($in) {
      return $cv->croak({ category => 'environment', message => "Unable to open template $filename for read: $!" }) unless $in;
      aio_read $in, $length, sub($data) {
        $in->close();
        $cv->send(Text::Template->new(TYPE => 'STRING', DELIMITERS => ['{%', '%}'], SOURCE => decode_utf8($data)));
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

sub fill_in($template, $data) {
  unless ($Config{template}{caching} && $templates{$template}) {
    $templates{$template} = read_template("$Config{server}{views}/$template.tt");
  };
  return $templates{$template}->fill_in(HASH => $data);
}

1;
