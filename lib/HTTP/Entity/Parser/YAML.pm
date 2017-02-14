package HTTP::Entity::Parser::YAML;

use strict;
use warnings;

use YAML::XS;

use Encode;

sub new {
  bless [''], $_[0];
}

sub add {
    my $self = shift;
    if (defined $_[0]) {
        $self->[0] .= $_[0];
    }
}

sub finalize {
  my $self = shift;
  my @params;
  return (\@params, []);
}

1;

__END__

=encoding utf-8

=head1 NAME

HTTP::Entity::Parser::YAML - parser for application/yaml

=head1 SYNOPSIS

    use HTTP::Entity::Parser;

    my $parser = HTTP::Entity::Parser->new;
    $parser->register('application/yaml','HTTP::Entity::Parser::YAML');

=head1 LICENSE

Copyright (C) 2017 Tim Bollman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Tim Bopllman <lt>tbollman@kevdenti.comE<gt>

=cut
