-- Verify SimpleMed:users on pg

BEGIN;

SELECT
    status,
    prevents_login,
    description
FROM app.user_status
WHERE FALSE;

SELECT
    user_id,
    username,
    password,
    status
FROM app.users
WHERE FALSE;

ROLLBACK;
