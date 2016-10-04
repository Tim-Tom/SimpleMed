-- Deploy SimpleMed:users to pg
-- requires: appschema

BEGIN;

CREATE TABLE app.user_status (
    status         VARCHAR(50) NOT NULL,
    prevents_login BOOLEAN     NOT NULL,
    description    TEXT        NOT NULL,
    PRIMARY KEY (status)
);

INSERT INTO app.user_status
VALUES
    ('active', false, 'User is active');

CREATE TABLE app.users (
    user_id     INT          NOT NULL,
    username    VARCHAR(50)  NOT NULL,
    password    CHAR(32)     NOT NULL,
    status      VARCHAR(50)  NOT NULL,
    PRIMARY KEY (user_id),
    CONSTRAINT UK_username UNIQUE (username),
    CONSTRAINT FK_user_id FOREIGN KEY (user_id)
        REFERENCES app.people (person_id)
);

COMMIT;
