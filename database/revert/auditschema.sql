-- Revert SimpleMed:auditschema from pg

BEGIN;

DROP SCHEMA audit;

COMMIT;
