package SimpleMed::Views;

use v5.24;

use strict;
use feature 'signatures';
use feature 'postderef';

use SimpleMed::Template qw(get_template_strict template_strict);

use HTML::Entities qw();

sub escape {
  return '' unless $_[0];
  my $result = HTML::Entities::encode_entities($_[0]);
  $result =~ s!\n!<br />!g;
  return $result;
}

1;
