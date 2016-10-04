-- Revert SimpleMed:people from pg

BEGIN;

DROP TABLE app.people;
DROP TYPE app.gender;
DROP SEQUENCE app.seq_people;

COMMIT;
