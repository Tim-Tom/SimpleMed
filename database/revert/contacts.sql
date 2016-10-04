-- Revert SimpleMed:contacts from pg

BEGIN;


DROP TABLE contact_emails;
DROP TABLE contact_phones;
DROP TABLE app.emergency_contacts;
DROP TABLE app.addresses;
DROP TYPE emergency_contact_type;

COMMIT;
