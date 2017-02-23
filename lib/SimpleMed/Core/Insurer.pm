package SimpleMed::Core::Insurer;

use v5.22;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

our %cache;

sub pick {
  my ($hash, @keys) = @_;
  return map { $_ => $hash->{$_} } @keys;
}

sub omit {
  my ($hash, @keys) = @_;
  return map { $_ => $hash->{$_} } grep { my $k = $_; !grep { $_  eq $k } @keys } keys %$hash;
}

my @db_keys = qw(insurance_id company phone address notes);
my $db_columns = join(', ', @db_keys);

sub load($dbh) {
  my @rows = $dbh->execute("SELECT $db_columns FROM app.insurance_info");
  foreach my $row (@rows) {
    my $insurer = { map { $db_keys[$_] => $row->[$_] } 0 .. $#db_keys };
    $cache{$insurer->{insurance_id}} = $insurer;
  }
  return scalar keys %cache;
}

sub search_by_name($substring) {
  return sort { $a->{company} cmp $b->{company} } grep { $_->{company} =~ /\Q$substring\E/ } values %cache;
}

1;
