package SimpleMed::Core;

use strict;
use warnings;

use v5.22;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use Try::Tiny;

use SimpleMed::Core::Instance::Person;

use SimpleMed::Core::User;
use SimpleMed::Core::Person;
use SimpleMed::Core::Insurer;

use SimpleMed::Storage;

sub LoadAll {

  my %frozen = %{SimpleMed::Storage::instance->load};
  my @connect;
  foreach my $frozen (values %{$frozen{'SimpleMed::Core::Instance::Person'}}) {
    my ($instance, $connectors) = SimpleMed::Core::Instance::Person->THAW($frozen);
    SimpleMed::Core::Person::add($instance);
    if ($connectors) {
      push(@connect, [$instance, $connectors]);
    }
  }
  # TODO: Other Types...

  foreach my $connect (@connect) {
    my ($instance, $connectors) = @$connect;
    $instance->CONNECT($connectors);
  }
}

sub DumpAll {
  my %frozen;
  foreach my $instance (values %SimpleMed::Core::Person::cache) {
    $frozen{'SimpleMed::Core::Instance::Person'}{$instance->id} = $instance->FREEZE;
  }
  return SimpleMed::Storage::instance->full_dump(\%frozen);
}

1;
