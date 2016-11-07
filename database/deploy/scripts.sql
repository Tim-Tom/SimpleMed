-- Deploy SimpleMed:scripts to pg

BEGIN;

CREATE SEQUENCE app.seq_script_templates;

CREATE TABLE app.script_templates (
    script_template_id INT NOT NULL DEFAULT nextval('app.seq_script_templates'),
    parent_template_id INT     NULL,
    PRIMARY KEY (script_template_id),
    CONSTRAINT FK_parent_template_id FOREIGN KEY (parent_template_id)
        REFERENCES app.script_templates (script_template_id)
);

CREATE TABLE app.script_template_names (
    script_template_id INT          NOT NULL,
    name               VARCHAR(100) NOT NULL,
    PRIMARY KEY 
);

CREATE SEQUENCE app.seq_script_templates;

CREATE TABLE app.script_template_herbs (
    script_template_herb_id BIGINT NOT NULL nextval('app.script_template_herb_id'),
    script_template_id      INT    NOT NULL,
    herb_id                 INT    NOT NULL,
    instructions            TEXT       NULL,
    PRIMARY KEY (script_template_herb_id)
);

CREATE TABLE app.scripts (
    person_id          INT NOT NULL,
    script_template_id INT NOT NULL
);

COMMIT;
