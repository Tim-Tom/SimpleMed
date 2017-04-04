package SimpleMed::Core::People;

use v5.22;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use SimpleMed::Core::Insurer;
use SimpleMed::Common qw(clone omit);
use SimpleMed::Logger qw(:methods);

our %cache;
my $max_id;

sub find_by_id($id) {
  return $cache{$id};
}

sub get {
  my @sort_keys = @_ || qw(last_name first_name middle_name id);
  my @result = sort {
    foreach my $key (@sort_keys) {
      no warnings;
      my $cmp = $a->$key cmp $b->$key;
      return $cmp if $cmp;
    }
    return 0;
  } values(%cache);
  return @result;
}

sub add($person) {
  if ($person->id > $max_id) {
    $max_id = $person->id;
  }
  $cache{$person->id} = $person;
  return $person;
}

sub create($new_person) {
  # TODO: Insurer & contacts?
  my $person = SimpleMed::Core::Instance::Person->new(%$new_person, id => ++$max_id);
  $cache{$person->id} = $person;
  return $person;
}

sub update($person_id, $updated_person) {
  my $person = $cache{$person_id};
  foreach my $attr (%$updated_person) {
    $person->$attr($updated_person->{$attr});
  }
  return $person;
}

sub update_addresses($person_id, @addresses) {
  return update($person_id, { addresses => [@addresses] });
}

sub update_emails($dbh, $person_id, @emails) {
  return update($person_id, { emails => [@emails] });
}

sub update_phones($dbh, $person_id, @phones) {
  return update($person_id, { phones => [@phones] });
}

1;
