-- Deploy SimpleMed:herbs to pg

-- [2016-11-16]: Disabled

BEGIN;

CREATE SEQUENCE app.seq_herbs;

CREATE TABLE app.herbs (
    herb_id INT NOT NULL DEFAULT nextval('app.seq_herbs'),
    PRIMARY KEY (herb_id)
);

CREATE TABLE app.herb_names (
    herb_id INT         NOT NULL,
    name    VARCHAR(50) NOT NULL,
    PRIMARY KEY (herb_id, name),
    CONSTRAINT FK_herb_id FOREIGN KEY (herb_id)
        REFERENCES app.herbs (herb_id)
);

CREATE INDEX IX_herb_names_name_herb_id ON app.herb_names (name, herb_id);


COMMIT;
