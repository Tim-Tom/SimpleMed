CREATE USER SimpleMedApplication with password 'password';

CREATE ROLE SimpleMed_app_rw WITH USER SimpleMedApplication;

GRANT USAGE ON SCHEMA app TO SimpleMed_app_rw;

GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE
ON ALL TABLES IN SCHEMA app TO SimpleMed_app_rw;


GRANT SimpleMed_app_rw TO SimpleMedApplication;

INSERT INTO app.users (user_id, username, password, status)
VALUES (DEFAULT, 'SimpleMed', '{SSHA}rJuao0kqjME4k3Qfm5diTCIZAwKvo2dZ', 'active'); -- password: password
