-- Revert SimpleMed:insurance_info from pg

BEGIN;

DROP TABLE app.insurance_info;
DROP SEQUENCE app.seq_insurance_info;

COMMIT;
