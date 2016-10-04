-- Deploy SimpleMed:contacts to pg
-- requires: appschema
-- requires: people

BEGIN;

CREATE TABLE app.contact_emails (
    person_id INT         NOT NULL,
    order_id  INT         NOT NULL,
    email     VARCHAR(50) NOT NULL,
    PRIMARY KEY (person_id, order_id),
    CONSTRAINT UK_person_id_email UNIQUE (person_id, email), 
    CONSTRAINT FK_person_id FOREIGN KEY (person_id)
        REFERENCES app.people (person_id)
);

CREATE TABLE app.contact_phones (
    person_id INT         NOT NULL,
    order_id  INT         NOT NULL,
    phone     VARCHAR(16) NOT NULL,
    type      VARCHAR(50)     NULL,
    PRIMARY KEY (person_id, order_id),
    CONSTRAINT UK_person_id_phone UNIQUE (person_id, phone),
    CONSTRAINT FK_person_id FOREIGN KEY (person_id)
        REFERENCES app.people (person_id)
);

CREATE TYPE app.emergency_contact_type AS ENUM ('spouse', 'parent', 'child', 'grandparent', 'grandchild', 'sibling', 'family', 'friend', 'coworker');

CREATE TABLE app.emergency_contacts (
    person_id  INT                        NOT NULL,
    order_id   INT                        NOT NULL,
    contact_id INT                        NOT NULL,
    type       app.emergency_contact_type     NULL,
    PRIMARY KEY (person_id, order_id),
    CONSTRAINT UK_person_id_contact_id UNIQUE (person_id, contact_id),
    CONSTRAINT FK_person_id FOREIGN KEY (person_id)
        REFERENCES app.people (person_id),
    CONSTRAINT FK_contact_id FOREIGN KEY (contact_id)
        REFERENCES app.people (person_id)
);

CREATE TABLE app.addresses (
    person_id INT         NOT NULL,
    order_id  INT         NOT NULL,
    type      VARCHAR(50)     NULL,
    address   TEXT        NOT NULL,
    PRIMARY KEY (person_id, order_id),
    CONSTRAINT UK_person_id_type UNIQUE (person_id, type),
    CONSTRAINT FK_person_id FOREIGN KEY (person_id)
        REFERENCES app.people (person_id)
);

COMMIT;
