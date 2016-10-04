-- Revert SimpleMed:insurers from pg

BEGIN;

DROP TABLE app.insurers;

COMMIT;
