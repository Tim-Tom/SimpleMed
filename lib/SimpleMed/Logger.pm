package SimpleMed::Logger;

use v5.24;

# I hate to do this, but all the logging frameworks I see are for generating printf style
# log messages, I want structured log messages from the start. It looks like log4perl
# could do this using the log message format and I'm going to heavily base my framework on
# that, but for now I'm just going to do it myself. The other design consideration on this
# is that becasue I'm still planning on supporting callbacks doing things like logging, I
# have to pass everything via direct variables instead of doing it magically via localized
# package variables.

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use SimpleMed::Config qw(%Config);

use Exporter qw(import);

our %EXPORT_TAGS = (
  methods => [qw(Trace Debug Info Warn Error Fatal)]
);

our @EXPORT_OK = ('get_logger', map {@$_} values %EXPORT_TAGS);

our $Logger;

package SimpleMed::Logger::Adapter {
  use SimpleMed::Logger::Provider::Console;
  use SimpleMed::Logger::Provider::File;
  use SimpleMed::Logger::Formatter::JSON;
  use SimpleMed::Logger::Formatter::YAML;
  use SimpleMed::Logger::Formatter::Console;
  my %providers = (
    console => 'SimpleMed::Logger::Provider::Console',
    file => 'SimpleMed::Logger::Provider::File'
   );
  my %formatters = (
    json => 'SimpleMed::Logger::Formatter::JSON',
    yaml => 'SimpleMed::Logger::Formatter::YAML',
    console => 'SimpleMed::Logger::Formatter::Console'
   );

  sub new($class, $args) {
    my $levels = $args->{levels};
    my $provider = $providers{$args->{provider}{class}};
    my $formatter = $formatters{$args->{formatter}{class}};
    die "Provider $args->{provider}{class} isn't supported" unless $provider;
    die "Formatter $args->{formatter}{class} isn't supported" unless $formatter;
    $provider = $provider->new($args->{provider});
    $formatter = $formatter->new($args->{formatter});
    return bless { levels => $levels, provider => $provider, formatter => $formatter }, $class;
  }

  sub handles($self, $level) {
    return scalar grep {$_ eq $level} @{$self->{levels}};
  }

  sub log_data($self, $data) {
    $self->{provider}->send_data($self->{formatter}->format_data($data), $data);
  }
};

sub new($class, $config) {
  my @adapters;
  foreach my $adapt ($config->{adapters}->@*) {
    push(@adapters, SimpleMed::Logger::Adapter->new($adapt));
  }
  return bless {adapters => \@adapters}, $class;
}

sub get_logger {
  if (!defined $Logger) {
    $Logger = __PACKAGE__->new($Config{logging});
    foreach my $adapt ($Config{logging}{adapters}->@*) {
      $Logger->debug(q^Set up Log Source^, $adapt);
    }
  }
  return $Logger;
}

sub trace($self, $message_id, $payload={}, $opts={}) {
  $self->_log('trace', $message_id, $payload, $opts);
}

sub Trace {
  get_logger->trace(@_);
}

sub debug($self, $message_id, $payload={}, $opts={}) {
  $self->_log('debug', $message_id, $payload, $opts);
}

sub Debug {
  get_logger->debug(@_);
}

sub info($self, $message_id, $payload={}, $opts={}) {
  $self->_log('info', $message_id, $payload, $opts);
}

sub Info {
  get_logger->info(@_);
}

sub warn($self, $message_id, $payload={}, $opts={}) {
  $self->_log('warn', $message_id, $payload, $opts);
}

sub Warn {
  get_logger->warn(@_);
}

sub error($self, $message_id, $payload={}, $opts={}) {
  $self->_log('error', $message_id, $payload, $opts);
}

sub Error {
  get_logger->error(@_);
}

sub fatal($self, $message_id, $payload={}, $opts={}) {
  $self->_log('fatal', $message_id, $payload, $opts);
}

sub Fatal {
  get_logger->fatal(@_);
}

my $log_sequence_id = 0;

sub _log($self, $level, $message_id, $payload, $opts) {
  my @adapters = grep { $_->handles($level) } @{$self->{adapters}};
  return unless @adapters;
  $payload = ref($payload) eq 'CODE' ? $payload->() : $payload;
  my %data = (
    level => $level,
    pid => $$,
    sequence_id => ++$log_sequence_id,
    $opts->%*,
    message_id => $message_id,
    payload => $payload
  );
  foreach my $adapter (@adapters) {
    # This isn't great because I re-encode the data every time. If I have multiple things
    # all logging the same structure, I could generate it once and log it multiple times.
    $adapter->log_data(\%data);
  }
}

1;
