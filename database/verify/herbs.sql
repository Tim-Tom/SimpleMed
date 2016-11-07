-- Verify SimpleMed:herbs on pg

BEGIN;

SELECT
    herb_id
FROM app.herbs
WHERE FALSE;

SELECT
    herb_id,
    name
FROM app.herb_names
WHERE FALSE;

ROLLBACK;
