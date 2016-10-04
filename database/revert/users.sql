-- Revert SimpleMed:users from pg

BEGIN;

DROP TABLE app.users;
DROP TABLE app.user_status;

COMMIT;
