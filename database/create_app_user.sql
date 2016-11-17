CREATE USER SimpleMedApplication with password 'password';

CREATE ROLE SimpleMed_app_rw WITH USER SimpleMedApplication;

GRANT USAGE ON SCHEMA app TO SimpleMed_app_rw;

GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE
ON ALL TABLES IN SCHEMA app TO SimpleMed_app_rw;


GRANT SimpleMed_app_rw TO SimpleMedApplication;


INSERT INTO app.people (person_id, first_name, middle_name, last_name, gender, birth_date)
VALUES (1, 'SimpleMed', NULL, 'Admin', NULL, NULL);

INSERT INTO app.users (user_id, username, password, status)
VALUES (1, 'SimpleMed', '{SSHA}rJuao0kqjME4k3Qfm5diTCIZAwKvo2dZ', 'active'); -- password: password
