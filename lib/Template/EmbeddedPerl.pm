package Template::EmbeddedPerl;

use v5.10;

use strict;
use warnings;

use Const::Fast;

const my $state_done => 0;
const my $state_text => 1;
const my $state_code => 2;
const my $state_do => 3;
const my $state_do_escape => 4;

sub new {
  my ($class, %args) = @_;
  my %self;
  $self{config} = $args{config};
  if ($args{source}) {
    $self{filename} = $args{filename} // 'template';
    $self{source} = $args{source}
  } else {
    use File::Slurp qw(read_file);
    use Unicode::UTF8 qw(decode_utf8);

    die "Either source or filename are required arguments" unless $args{filename};
    $self{source} = decode_utf8(scalar read_file($args{filename}, {binmode => ':raw' }));
    if (!$args{config}) {
      $self{config} = $args{filename};
      $self{config} =~ s/\.\w+$/.yml/;
    }
  }
  $self{config} //= {};
  if (!ref $self{config}) {
    use File::Slurp qw(read_file);
    use Unicode::UTF8 qw(decode_utf8);

    $self{config} = YAML::XS::Load(decode_utf8(scalar read_file($self{config}, {binmode => ':raw' })));
  }
  $self{preamble} = $args{preamble} // '';
  my $self = bless(\%self, $class);
  $self->_compile();
  return $self;
}

sub fill_in {
  my ($self, $args) = @_;
  if ($args) {
    return $self->{sub}(%$args);
  } else {
    return $self->{sub}();
  }
}

sub _insert_text {
  my $self = shift;
  return unless $self->{buffer};
  $self->{buffer} =~ s/([#\$\@\%\\])/\\$1/g;
  $self->{line_no} += $self->{buffer} =~ s/\n/\\n/g;
  $self->{sub_text} .= '$OUT .= qq#' . $self->{buffer} . "#;\n";
  $self->{buffer} = '';
}

sub _setup_preamble {
  my $self = shift;
  my $package = $self->{config}{package} || 'Template::EmbeddedPerl::Templates';
  $self->{sub_text} = "package $package;\n$self->{preamble}\nsub {\nmy \$OUT = q##;\n";
  if (exists $self->{config}{variables}) {
    $self->{sub_text} .= "my \%variables = \@_;\n";
    foreach my $variable ($self->{config}{variables}->@*) {
      my $sigil = substr($variable, 0, 1);
      my $sigilless = substr($variable, 1);
      if ($sigil eq '$') {
        $self->{sub_text} .= "my $variable = \$variables{$sigilless};\n"
      } elsif ($sigil eq '@') {
        $self->{sub_text} .= "my $variable = \@{\$variables{$sigilless} || []};\n"
      } elsif ($sigil eq '%') {
        $self->{sub_text} .= "my $variable = \%{\$variables{$sigilless} || {}};\n"
      }
    }
    if (exists $self->{config}{unpack_func}) {
      while(my ($parent, $variables) = each $self->{config}{unpack_func}->%*) {
        foreach my $variable ($variables->@*) {
          my $sigil = substr($variable, 0, 1);
          my $sigilless = substr($variable, 1);
          if ($sigil eq '$') {
            $self->{sub_text} .= "my $variable = $parent\->$sigilless();\n"
          } elsif ($sigil eq '@') {
            $self->{sub_text} .= "my $variable = \@{$parent\->$sigilless() || []};\n"
          } elsif ($sigil eq '%') {
            $self->{sub_text} .= "my $variable = \%{$parent\->$sigilless() || {}};\n"
          }
        }
      }
    }
  }
}

sub _compile {
  my $self = shift;
  my $cur_text = $self->{source};
  my $strip_mode = 0;
  my $state = $state_text;
  $self->{buffer} = '';
  $self->{line__no} = 1;
  $self->_setup_preamble();
  while(1) {
    if ($state == $state_text) {
      my $index = index($cur_text, '<%');
      if ($index == -1) {
        $self->{buffer} .= $cur_text;
        $state = $state_done;
        last;
      }
      if (substr($cur_text, $index + 2, 1) eq '%') {
        $self->{buffer} .= substr($cur_text, 0, $index + 2);
        $cur_text = substr($cur_text, $index + 3);
      } else {
        $self->{buffer} .= substr($cur_text, 0, $index);
        $index += 2;
        if (substr($cur_text, $index, 1) eq '`') {
          $strip_mode = 1;
          ++$index;
        }
        my $variant = substr($cur_text, $index, 1);
        if ($variant eq '-') {
          $state = $state_do;
          ++$index;
        } elsif ($variant eq '=') {
          $state = $state_do_escape;
          ++$index;
        } else {
          $state = $state_code;
        }
        $cur_text = substr($cur_text, $index);
      }
    } else {
      $self->{buffer} =~ s/[ \t]*$// if $strip_mode;
      $self->_insert_text;
      my $index = index($cur_text, '%>');
      if ($index == -1) {
        die "Unexpected end of input in code block started at line $self->{line_no}";
      }
      my $line = "#line $self->{line_no} $self->{filename}";
      my $code_text = substr($cur_text, 0, $index);
      $self->{line_no} += ($code_text =~ tr/\n/\n/);
      $code_text =~ s/^\s+//;
      $code_text =~ s/\s+$//;
      if ($state == $state_do) {
        $self->{sub_text} .= "\$OUT .= do {\n$line\n$code_text\n};\n";
      } elsif ($state == $state_do_escape) {
        $self->{sub_text} .= "\$OUT .= escape do {\n$line\n$code_text\n};\n";
      } else {
        $self->{sub_text} .= "$line\n$code_text\n";
      }
      $cur_text = substr($cur_text, $index + 2);
      if ($strip_mode) {
        $cur_text =~ /^[ \t]*\n?/;
        if ($+[0]) {
          if (substr($cur_text, $+[0] - 1, 1) eq "\n") {
            ++$self->{line_no};
          }
          $cur_text = substr($cur_text, $+[0]);
        }
        $strip_mode = 0;
      }
      $state = $state_text;
    }
  }
  $self->_insert_text;
  $self->{sub_text} .= "return \$OUT;\n}\n";
  {
    no strict;
    no warnings;
    $self->{sub} = eval $self->{sub_text};
  }
  if ($@) {
    die {
      error => $@,
      sub_text => $self->{sub_text}
    }
  }
  return $self->{sub};
}

1;
