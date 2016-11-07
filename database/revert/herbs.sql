-- Revert SimpleMed:herbs from pg

BEGIN;

DROP TABLE app.herb_names;
DROP TABLE app.herbs;
DROP SEQUENCE app.seq_herbs;

COMMIT;
