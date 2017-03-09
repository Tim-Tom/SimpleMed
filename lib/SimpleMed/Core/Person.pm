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
use SimpleMed::Logger qw(:methods);

our %cache;

sub clean_person($person) {
  return undef if !defined $person;
  my $new = clone $person;
  $new->{insurer} = clone $new->{insurer}{insurer};
  $new->{insurer}{number} = $person->{insurer}{insurance_number};
  $new->{emergency_contacts} = [map {my $c = omit($_->{contact}, 'emergency_contacts'); $c->{relationship} = $_->{type}; $c } $new->{emergency_contacts}->@*];
  return $new;
}

my @db_keys = qw(person_id first_name middle_name last_name gender birth_date time_zone);
my $db_columns = join(', ', @db_keys);

sub load($dbh) {
  my @rows = $dbh->execute("SELECT $db_columns FROM app.people");
  for my $row (@rows) {
    my $person = { map { $db_keys[$_] => $row->[$_] } 0 .. $#db_keys };
    $person->{addresses} = [];
    $person->{emails} = [];
    $person->{phones} = [];
    $person->{emergency_contacts} = [];
    $person->{insurer} = {};
    $cache{$person->{person_id}} = $person;
  }

  @rows = $dbh->execute('SELECT person_id, type, address FROM app.addresses order by person_id, order_id');
  for my $row (@rows) {
    my ($person_id, $type, $address) = @$row;
    push($cache{$person_id}{addresses}->@*, { address => $address, type => $type });
  }

  @rows = $dbh->execute('SELECT person_id, email FROM app.contact_emails order by person_id, order_id');
  for my $row (@rows) {
    my ($person_id, $email) = @$row;
    push($cache{$person_id}{emails}->@*, $email);
  }

  @rows = $dbh->execute('SELECT person_id, type, number FROM app.contact_phones order by person_id, order_id');
  for my $row (@rows) {
    my ($person_id, $type, $number) = @$row;
    push($cache{$person_id}{phones}->@*, {number => $number, type => $type});
  }

  @rows = $dbh->execute('SELECT person_id, contact_id, type FROM app.emergency_contacts order by person_id, order_id');
  for my $row (@rows) {
    my ($person_id, $contact_id, $type) = @$row;
    push($cache{$person_id}{emergency_contacts}->@*, { type => $type, contact => $cache{$contact_id} });
  }

  @rows = $dbh->execute('SELECT person_id, insurance_id, insurance_number FROM app.insurers order by person_id, insurance_id');
  for my $row (@rows) {
    my ($person_id, $insurance_id, $insurance_number) = @$row;
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
      no warnings;
      my $cmp = $a->{$key} cmp $b->{$key};
      return $cmp if $cmp;
    }
    return 0;
  } map { clean_person($_) }  values(%cache);
  return @result;
}

sub create($dbh, $new_person) {
  my $query = "INSERT INTO app.people ($db_columns) VALUES (DEFAULT, ?, ?, ?, ?, ?, ?) RETURNING $db_columns;";
  my @rows = $dbh->execute($query, $new_person->@{qw(first_name middle_name last_name gender birth_date time_zone)});
  my $person = { map { $db_keys[$_] => $rows[0][$_] } 0 .. $#db_keys };
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
  $dbh->execute("UPDATE app.people SET $cols WHERE person_id = ?", $updated_person->@{@attributes}, $person_id);
  my $person = $cache{$person_id};
  $person->@{@attributes} = $updated_person->@{@attributes};
  return clean_person $person;
}

sub update_addresses($dbh, $person_id, @addresses) {
  my $person = $cache{$person_id};
  my $placeholders = join(', ', map { '(?, ?, ?, ?)' } @addresses);
  Debug(q^Updating Addresses^, { person_id => $person_id, old => $person->{addresses}, new => \@addresses });
  # This is bad because we don't have a transaction around it, so the delete could occur without the insert.
  $dbh->execute("DELETE FROM app.addresses wHERE person_id = ?;", $person_id);
  $dbh->execute("INSERT INTO app.addresses (person_id, order_id, type, address) VALUES $placeholders;", map { $person_id, $_->{order}, $_->{type}, $_->{address} } @addresses);
  $person->{addresses} = [map { { type => $_->[0], address => $_->[1] }; } $dbh->execute("SELECT type, address from app.addresses WHERE person_id = ? ORDER BY order_id", $person_id)];
  return clean_person $person;
}

sub update_emails($dbh, $person_id, @emails) {
  my $person = $cache{$person_id};
  my $placeholders = join(', ', map { '(?, ?, ?)' } @emails);
  Debug(q^Updating Emails^, { person_id => $person_id, old => $person->{emails}, new => \@emails });
  # This is bad because we don't have a transaction around it, so the delete could occur without the insert.
  $dbh->execute("DELETE FROM app.contact_emails WHERE person_id = ?;", $person_id);
  $dbh->execute("INSERT INTO app.contact_emails (person_id, order_id, email) VALUES $placeholders;", map { $person_id, $_->{order}, $_->{email} } @emails);
  $person->{emails} = [map { $_->[0] } $dbh->execute("SELECT email from app.contact_emails WHERE person_id = ? ORDER BY order_id", $person_id)];
  return clean_person $person;
}

sub update_phones($dbh, $person_id, @phones) {
  my $person = $cache{$person_id};
  my $placeholders = join(', ', map { '(?, ?, ?, ?)' } @phones);
  Debug(q^Updating Phones^, { person_id => $person_id, old => $person->{phones}, new => \@phones });
  # This is bad because we don't have a transaction around it, so the delete could occur without the insert.
  $dbh->execute("DELETE FROM app.contact_phones wHERE person_id = ?;", $person_id);
  $dbh->execute("INSERT INTO app.contact_phones (person_id, order_id, type, number) VALUES $placeholders;", map { $person_id, $_->{order}, $_->{type}, $_->{number} } @phones);
  $person->{phones} = [map { { type => $_->[0], number => $_->[1] }; } $dbh->execute("SELECT type, number from app.contact_phones WHERE person_id = ? ORDER BY order_id", $person_id)];
  return clean_person $person;
}

1;
