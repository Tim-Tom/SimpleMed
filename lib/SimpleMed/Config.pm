package SimpleMed::Config;

use v5.24;

use strict;
use warnings;

use File::Slurp qw(read_file);
use Unicode::UTF8 qw(decode_utf8);

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use YAML::XS;

use Encode qw(decode);

our %Config;

sub create($config_filename, $server_root) {
  my $config_text = do {
    decode_utf8(scalar read_file($config_filename, {binmode => ':raw' }));
  };
  %Config = %{YAML::XS::Load($config_text)};
  # TODO: We should probably validate the keys to make sure there are no stupid typos. Perhaps https://github.com/rjbs/rx?
  $Config{server} = {
    root => $server_root
   };
  return %Config;
}

1;
