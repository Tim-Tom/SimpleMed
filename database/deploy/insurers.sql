-- Deploy SimpleMed:insurers to pg
-- requires: appschema
-- requires: insurance_info
-- requires: people

BEGIN;

CREATE TABLE app.insurers (
    person_id        INT         NOT NULL,
    insurance_id     INT         NOT NULL,
    insurance_number VARCHAR(50) NOT NULL,
    PRIMARY KEY (person_id, insurance_id),
    CONSTRAINT FK_person_id FOREIGN KEY (person_id)
        REFERENCES app.people (person_id),
    CONSTRAINT FK_insurance_id FOREIGN KEY (insurance_id)
        REFERENCES app.insurance_info (insurance_id)
);

COMMIT;
