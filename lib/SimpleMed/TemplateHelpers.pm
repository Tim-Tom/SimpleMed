package SimpleMed::TemplateHelpers;

use strict;
use warnings;

use HTML::Entities qw();

use SimpleMed::Template;

use Exporter qw(import);

our @EXPORT = qw(e ea get_template template template_pkg);

use subs qw(get_template template template_pkg);

sub e {
  return '' unless $_[0];
  my $result = HTML::Entities::encode_entities($_[0]);
  $result =~ s!\n!<br />!g;
  return $result;
}

sub ea {
  return map { e($_) } @_;
}

*SimpleMed::TemplateHelpers::get_template = \&SimpleMed::Template::get_template;
*SimpleMed::TemplateHelpers::template = \&SimpleMed::Template::template;
*SimpleMed::TemplateHelpers::template_pkg = \&SimpleMed::Template::template_pkg;

1;
