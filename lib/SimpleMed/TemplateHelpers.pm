package SimpleMed::Template_Helpers;

use strict;
use warnings;

use HTML::Entities qw();

use SimpleMed::Template qw(get_template fill_in);

use Exporter qw(import);

our @EXPORT = qw(e ea get_template fill_in);

sub e {
  return '' unless $_[0];
  my $result = HTML::Entities::encode_entities($_[0]);
  $result =~ s!\n!<br />!g;
  return $result;
}

sub ea {
  return map { e($_) } @_;
}

1;
