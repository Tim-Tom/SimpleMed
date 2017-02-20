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

sub load($dbh) {
  my $sth = $dbh->prepare('SELECT insurance_id, company, phone, address, notes FROM app.insurance_info') or die {message => $dbh->errstr, code => 500 };
  $sth->execute() or die {message => $sth->errstr, code => 500 };
  while(my $insurer = $sth->fetchrow_hashref()) {
    $cache{$insurer->{insurance_id}} = $insurer;
  }
  return scalar keys %cache;
}

sub search_by_name($substring) {
  return sort { $a->{company} cmp $b->{company} } grep { $_->{company} =~ /\Q$substring\E/ } values %cache;
}

1;
