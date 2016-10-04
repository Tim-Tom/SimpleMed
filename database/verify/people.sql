-- Verify SimpleMed:people on pg

BEGIN;

SELECT
    person_id,
    first_name,
    middle_name,
    last_name,
    gender,
    birth_date,
    time_zone
FROM app.people
WHERE FALSE;

ROLLBACK;
