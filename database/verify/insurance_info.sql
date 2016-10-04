-- Verify SimpleMed:insurance_info on pg

BEGIN;

SELECT
    insurance_id,
    company,
    phone,
    address,
    notes
FROM app.insurance_info
WHERE FALSE;

ROLLBACK;
