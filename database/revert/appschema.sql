-- Revert SimpleMed:appschema from pg

BEGIN;

DROP SCHEMA app;

-- XXX Add DDLs here.

COMMIT;
