-- Verify SimpleMed:contacts on pg

BEGIN;

SELECT
    person_id,
    order_id,
    email
FROM app.contact_emails
WHERE FALSE;

SELECT
    person_id,
    order_id,
    phone,
    type
FROM app.contact_phones
WHERE FALSE;

SELECT
    person_id,
    order_id,
    contact_id,
    type
FROM app.emergency_contacts
WHERE FALSE;

SELECT
    person_id,
    order_id,
    type,
    address
FROM app.addresses
WHERE FALSE;

ROLLBACK;
