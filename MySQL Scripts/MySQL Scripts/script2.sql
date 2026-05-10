USE healthbridge;

-- Create patients table referencing the OLD column name (DoctorID)
-- We will rename it later in R3
CREATE TABLE patients (
    patient_id      INT             NOT NULL AUTO_INCREMENT,
    full_name       VARCHAR(255)    NOT NULL,
    date_of_birth   DATE            NOT NULL,
    sex             CHAR(1)         NOT NULL,
    reg_doctor_id   INT,
    notes           TEXT,
    PRIMARY KEY (patient_id),
    CONSTRAINT fk_patient_doctor
        FOREIGN KEY (reg_doctor_id) REFERENCES doctors(DoctorID)
);

CREATE TABLE patient_phones (
    phone_id        INT             NOT NULL AUTO_INCREMENT,
    patient_id      INT             NOT NULL,
    phone_number    VARCHAR(20)     NOT NULL,
    phone_type      VARCHAR(20)     NOT NULL DEFAULT 'mobile',
    PRIMARY KEY (phone_id),
    CONSTRAINT fk_phone_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
            ON DELETE CASCADE
);

CREATE TABLE patient_addresses (
    address_id      INT             NOT NULL AUTO_INCREMENT,
    patient_id      INT             NOT NULL,
    address_line    VARCHAR(255)    NOT NULL,
    city            VARCHAR(100)    NOT NULL,
    address_type    VARCHAR(20)     NOT NULL DEFAULT 'home',
    PRIMARY KEY (address_id),
    CONSTRAINT fk_address_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
            ON DELETE CASCADE
);