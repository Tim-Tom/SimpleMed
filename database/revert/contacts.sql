-- Revert SimpleMed:contacts from pg

BEGIN;

DROP TABLE app.contact_emails;
DROP TABLE app.contact_phones;
DROP TABLE app.emergency_contacts;
DROP TABLE app.addresses;
DROP TYPE app.emergency_contact_type;

COMMIT;
