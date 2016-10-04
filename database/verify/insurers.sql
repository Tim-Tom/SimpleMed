-- Verify SimpleMed:insurers on pg

BEGIN;

SELECT
    person_id,
    insurance_id,
    insurance_number
FROM app.insurers;

ROLLBACK;
