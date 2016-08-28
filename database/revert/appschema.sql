-- Revert SimpleMed:appschema from pg

BEGIN;

DROP SCHEMA app;

COMMIT;
