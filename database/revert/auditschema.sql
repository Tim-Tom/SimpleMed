-- Revert SimpleMed:auditschema from pg

BEGIN;

DROP SCHEMA app;

COMMIT;
