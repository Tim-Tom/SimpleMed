-- Deploy SimpleMed:people to pg
-- requires: appschema
-- requires: people

BEGIN;

CREATE TYPE app.gender AS ENUM ('Male', 'Female');

CREATE SEQUENCE app.seq_people;

CREATE TABLE app.people (
    person_id   INT          NOT NULL DEFAULT nextval('app.seq_people'),
    first_name  VARCHAR(128) NOT NULL,
    middle_name VARCHAR(128)     NULL,
    last_name   VARCHAR(128) NOT NULL,
    gender      app.gender       NULL,
    birth_date  DATE             NULL,
    time_zone   VARCHAR(30)  NOT NULL DEFAULT 'America/Los_Angeles',
    PRIMARY KEY (person_id)
);

COMMIT;
