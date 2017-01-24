package SimpleMed::Core::Person;

use v5.22;

use strict;
use warnings;

no warnings 'experimental::signatures';
use feature 'signatures';

no warnings 'experimental::postderef';
use feature 'postderef';

use SimpleMed::Core::Insurer;
use SimpleMed::Common qw(clone omit);

our %cache;

sub clean_person($person) {
  return undef if !defined $person;
  my $new = clone $person;
  $new->{insurer} = clone $new->{insurer}{insurer};
  $new->{insurer}{number} = $person->{insurer}{insurance_number};
  $new->{emergency_contacts} = [map {my $c = omit($_->{contact}, 'emergency_contacts'); $c->{relationship} = $_->{type}; $c } $new->{emergency_contacts}->@*];
  return $new;
}

sub load($dbh) {
  my $sth = $dbh->prepare('SELECT person_id, first_name, middle_name, last_name, gender, birth_date, time_zone FROM app.people') or die {message => $dbh->errstr, code => 500 };
  $sth->execute() or die {message => $sth->errstr, code => 500 };
  while(my $person = $sth->fetchrow_hashref()) {
    $person->{addresses} = [];
    $person->{emails} = [];
    $person->{phones} = [];
    $person->{emergency_contacts} = [];
    $person->{insurer} = {};
    $cache{$person->{person_id}} = $person;
  }

  $sth = $dbh->prepare('SELECT person_id, type, address FROM app.addresses order by person_id, order_id') or die {message => $dbh->errstr, code => 500 };
  $sth->execute() or die {message => $sth->errstr, code => 500 };
  while(my ($person_id, $type, $address) = $sth->fetchrow_array()) {
    push($cache{$person_id}{addresses}->@*, { address => $address, type => $type });
  }

  $sth = $dbh->prepare('SELECT person_id, email FROM app.contact_emails order by person_id, order_id') or die {message => $dbh->errstr, code => 500 };
  $sth->execute() or die {message => $sth->errstr, code => 500 };
  while(my ($person_id, $email) = $sth->fetchrow_array()) {
    push($cache{$person_id}{emails}->@*, $email);
  }

  $sth = $dbh->prepare('SELECT person_id, type, phone FROM app.contact_phones order by person_id, order_id') or die {message => $dbh->errstr, code => 500 };
  $sth->execute() or die {message => $sth->errstr, code => 500 };
  while(my ($person_id, $type, $phone) = $sth->fetchrow_array()) {
    push($cache{$person_id}{phones}->@*, {number => $phone, type => $type});
  }

  $sth = $dbh->prepare('SELECT person_id, contact_id, type FROM app.emergency_contacts order by person_id, order_id') or die {message => $dbh->errstr, code => 500 };
  $sth->execute() or die {message => $sth->errstr, code => 500 };
  while(my ($person_id, $contact_id, $type) = $sth->fetchrow_array()) {
    push($cache{$person_id}{emergency_contacts}->@*, { type => $type, contact => $cache{$contact_id} });
  }

  $sth = $dbh->prepare('SELECT person_id, insurance_id, insurance_number FROM app.insurers order by person_id, insurance_id') or die {message => $dbh->errstr, code => 500 };
  $sth->execute() or die {message => $sth->errstr, code => 500 };
  while(my ($person_id, $insurance_id, $insurance_number) = $sth->fetchrow_array()) {
    $cache{$person_id}{insurer} = { insurance_number => $insurance_number, insurer => $SimpleMed::Core::Insurer::cache{$insurance_id} };
  }

  return scalar keys %cache;
}

sub find_by_id($id) {
  return clean_person $cache{$id};
}

sub get {
  my @sort_keys = @_ || qw(last_name first_name middle_name id);
  my @result = sort {
    foreach my $key (@sort_keys) {
      my $cmp = $a->{$key} cmp $b->{$key};
      return $cmp if $cmp;
    }
    return 0;
  } map { clean_person($_) }  values(%cache);
  return @result;
}

sub create($dbh, $new_person) {
  my $sth = $dbh->prepare('INSERT INTO app.people (first_name, middle_name, last_name, gender, birth_date, time_zone) VALUES (?, ?, ?, ?, ?, ?) RETURNING person_id, first_name, middle_name, last_name, gender, birth_date, time_zone;');
  $sth->execute($new_person->@{qw(first_name middle_name last_name gender birth_date time_zone)}) or die { message => $sth->errstr, code => 500 };
  my $person = $sth->fetchrow_hashref();
  $cache{$person->{person_id}} = $person;
  $person->{addresses} = [];
  $person->{emails} = [];
  $person->{phones} = [];
  $person->{emergency_contacts} = [];
  $person->{insurer} = {};
  return clean_person $person;
}

sub update($dbh, $person_id, $updated_person, @attributes) {
  my $cols = join(', ', map { "$_ = ?" } @attributes);
  my $sth = $dbh->prepare("UPDATE app.people SET $cols WHERE person_id = ?");
  $sth->execute($updated_person->@{@attributes}, $person_id) or die { message => $sth->errstr, code => 500 };
  my $person = $cache{$person_id};
  $person->@{@attributes} = $updated_person->@{@attributes};
  return clean_person $person;
}

1;
