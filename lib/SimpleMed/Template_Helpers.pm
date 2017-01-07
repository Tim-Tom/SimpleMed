package SimpleMed::Template_Helpers;

use strict;
use warnings;

use HTML::Entities qw();
use Exporter qw(import);

our @EXPORT_OK = qw(e ea);

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
