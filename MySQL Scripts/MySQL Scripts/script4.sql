USE healthbridge;

-- Need appointments table first
CREATE TABLE IF NOT EXISTS appointments (
    appt_id     INT,
    patient_id  INT,
    patient_nm  VARCHAR(255),
    patient_ph  VARCHAR(255),
    doc_id      INT,
    doc_name    VARCHAR(255),
    appt_date   VARCHAR(50),
    status      CHAR(1),
    fee         FLOAT,
    discount    FLOAT,
    net_fee     FLOAT,
    room        VARCHAR(255)
);

-- R2: Create status reference table and enforce via FK
CREATE TABLE appt_status_ref (
    status_code  CHAR(1)      NOT NULL,
    description  VARCHAR(50)  NOT NULL,
    PRIMARY KEY (status_code)
);

INSERT INTO appt_status_ref (status_code, description) VALUES
    ('P', 'Pending'),
    ('C', 'Completed'),
    ('X', 'Cancelled'),
    ('H', 'On Hold'),
    ('R', 'Rescheduled');

ALTER TABLE appointments
    ADD CONSTRAINT fk_appt_status
        FOREIGN KEY (status) REFERENCES appt_status_ref(status_code);