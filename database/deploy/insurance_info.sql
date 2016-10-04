-- Deploy SimpleMed:insurance_info to pg
-- requires: appschema

BEGIN;

CREATE SEQUENCE app.seq_insurance_info;

CREATE TABLE app.insurance_info (
    insurance_id INT          NOT NULL DEFAULT nextval('app.seq_insurance_info'),
    company      VARCHAR(128) NOT NULL,
    phone        VARCHAR(15)      NULL,
    address      TEXT             NULL,
    notes        TEXT             NULL,
    PRIMARY KEY (insurance_id)
);

COMMIT;
