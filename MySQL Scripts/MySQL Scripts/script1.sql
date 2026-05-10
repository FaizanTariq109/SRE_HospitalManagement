-- ============================================================
-- SOFTWARE RE-ENGINEERING FINAL PROJECT
-- Geeti Fatima (22F-3704) & Faizan Tariq (22F-3714)
-- Part F — Schema Normalisation and Refactoring
-- ============================================================


-- ============================================================
-- F1 STEP 2 — NORMALISED CREATE TABLE STATEMENTS (3NF)
-- ============================================================
-- Original pat_master is split into:
--   patients            → core patient identity
--   patient_phones      → repeating phone group (fixes 1NF)
--   patient_addresses   → repeating address group (fixes 1NF)
-- reg_doc / reg_doc_id removed → doctor already in doctors table (fixes 3NF)
-- total_visits / last_bill removed → derived from other tables (fixes 3NF)
-- dob changed from VARCHAR to DATE (fixes Type smell)
-- pid declared as PRIMARY KEY (fixes Missing Constraint smell)
-- ============================================================
CREATE DATABASE IF NOT EXISTS healthbridge;
USE healthbridge;

CREATE DATABASE IF NOT EXISTS healthbridge;
USE healthbridge;

-- Legacy tables first (needed for FK references)
CREATE TABLE departments (
    dept_id   INT          PRIMARY KEY,
    dept_nm   VARCHAR(255),
    hod       VARCHAR(255),
    budget    FLOAT
);

CREATE TABLE doctors (
    DoctorID  INT          PRIMARY KEY,
    FullName  VARCHAR(255),
    Speciality VARCHAR(255),
    ContactNo VARCHAR(255),
    JoinDt    VARCHAR(50),
    Salary    FLOAT,
    dept_id   INT,
    isActive  CHAR(1)
);

CREATE TABLE pat_master (
    pid         INT,
    p_name      VARCHAR(255),
    dob         VARCHAR(50),
    sex         CHAR(1),
    ph1         VARCHAR(255),
    ph2         VARCHAR(255),
    ph3         VARCHAR(255),
    addr1       VARCHAR(255),
    addr2       VARCHAR(255),
    city        VARCHAR(255),
    reg_doc     VARCHAR(255),
    reg_doc_id  VARCHAR(255),
    total_visits INT,
    last_bill   FLOAT,
    notes       TEXT
);

-- Core patient identity table (1NF, 2NF, 3NF compliant)
CREATE TABLE patients (
    patient_id      INT             NOT NULL AUTO_INCREMENT,
    full_name       VARCHAR(255)    NOT NULL,
    date_of_birth   DATE            NOT NULL,          -- was VARCHAR(50) 'DD/MM/YYYY'
    sex             CHAR(1)         NOT NULL,          -- 'M', 'F', 'N' (non-binary)
    reg_doctor_id   INT,                               -- FK to doctors; replaces reg_doc plain text
    notes           TEXT,
    PRIMARY KEY (patient_id),
    CONSTRAINT fk_patient_doctor
        FOREIGN KEY (reg_doctor_id) REFERENCES doctors(doctor_id)
);

-- One row per phone number per patient (fixes ph1/ph2/ph3 repeating group — 1NF)
CREATE TABLE patient_phones (
    phone_id        INT             NOT NULL AUTO_INCREMENT,
    patient_id      INT             NOT NULL,
    phone_number    VARCHAR(20)     NOT NULL,
    phone_type      VARCHAR(20)     NOT NULL DEFAULT 'mobile', -- 'mobile','home','work'
    PRIMARY KEY (phone_id),
    CONSTRAINT fk_phone_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
            ON DELETE CASCADE
);

-- One row per address component per patient (fixes addr1/addr2/city inline — 1NF)
CREATE TABLE patient_addresses (
    address_id      INT             NOT NULL AUTO_INCREMENT,
    patient_id      INT             NOT NULL,
    address_line    VARCHAR(255)    NOT NULL,
    city            VARCHAR(100)    NOT NULL,
    address_type    VARCHAR(20)     NOT NULL DEFAULT 'home', -- 'home','work'
    PRIMARY KEY (address_id),
    CONSTRAINT fk_address_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
            ON DELETE CASCADE
);


-- ============================================================
-- F1 STEP 3 — BEFORE AND AFTER COMPARISON (reference only)
-- ============================================================
-- Aspect                  | Before (pat_master)       | After (Normalised)
-- Number of tables        | 1                         | 3
-- Repeating phone cols    | ph1, ph2, ph3             | patient_phones table
-- Address storage         | Inline addr1/addr2/city   | patient_addresses table
-- Doctor reference        | reg_doc VARCHAR plain text| reg_doctor_id FK → doctors
-- Date of birth type      | VARCHAR(50)               | DATE
-- Primary key             | None defined              | patient_id INT AUTO_INCREMENT PK
-- Currency columns        | FLOAT (last_bill)         | Removed (derived via query)


-- ============================================================
-- F2 — FIVE SCHEMA REFACTORING SCRIPTS
-- ============================================================


-- ------------------------------------------------------------
-- R1: Fix Derived Data in billing (1.5 Marks)
-- Smell: Derived Data — tax_amt, grand_total, balance are
--        always computed from other columns. Storing them
--        physically means any update to svc_cost or tax_pct
--        requires manual recalculation of all three — a silent
--        inconsistency risk in financial records.
-- Fix:   Drop the three physical columns and replace with a
--        view that computes them on every read, guaranteeing
--        they are always consistent with source values.
-- ------------------------------------------------------------

ALTER TABLE billing DROP COLUMN tax_amt;
ALTER TABLE billing DROP COLUMN grand_total;
ALTER TABLE billing DROP COLUMN balance;

CREATE OR REPLACE VIEW v_billing_summary AS
SELECT
    bill_no,
    pid,
    pname,
    services,
    svc_cost,
    tax_pct,
    ROUND(svc_cost * tax_pct / 100, 2)                        AS tax_amt,
    ROUND(svc_cost + (svc_cost * tax_pct / 100), 2)           AS grand_total,
    paid,
    ROUND(svc_cost + (svc_cost * tax_pct / 100) - paid, 2)    AS balance,
    created,
    created_by
FROM billing;

-- Explanation:
-- The Derived Data smell occurs when values that can be computed from
-- other columns in the same table are stored as physical columns.
-- This view eliminates the inconsistency risk entirely: tax_amt,
-- grand_total and balance are now always computed from the current
-- svc_cost, tax_pct, and paid values at query time. No manual
-- recalculation is ever needed. Any application that previously
-- selected these columns from billing can select them from
-- v_billing_summary with no change to its SELECT statement.


-- ------------------------------------------------------------
-- R2: Fix Overloaded Column — appointments.status (1 Mark)
-- Smell: Magic Values / Encoded Nulls — status CHAR(1) stores
--        opaque codes whose meaning lives only in comments.
--        No constraint prevents invalid codes like 'W' or 'c'.
-- Fix:   Create a reference table and enforce via FK so the
--        database itself rejects any unknown status code.
-- ------------------------------------------------------------

CREATE TABLE appt_status_ref (
    status_code     CHAR(1)         NOT NULL,
    description     VARCHAR(50)     NOT NULL,
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

-- Explanation:
-- The Overloaded Column smell means a single column carries multiple
-- distinct meanings encoded as magic characters, with no database-level
-- enforcement. Before this fix, inserting status='W' or status='c'
-- would silently succeed. Now the FK constraint causes the database to
-- reject any status value not present in appt_status_ref, making
-- invalid appointment states structurally impossible. The reference
-- table also serves as self-documenting metadata — developers no
-- longer need to hunt through comment blocks to understand what 'H' means.


-- ------------------------------------------------------------
-- R3: Fix Inconsistent Naming — doctors table (1 Mark)
-- Smell: Inconsistent Naming — PascalCase, camelCase, and
--        abbreviations mixed in a single table. ORM tools like
--        Hibernate and Prisma treat column names as case-sensitive
--        identifiers, causing mapping failures at runtime.
-- Fix:   Rename all columns to lowercase snake_case.
-- ------------------------------------------------------------

ALTER TABLE doctors RENAME COLUMN DoctorID    TO doctor_id;
ALTER TABLE doctors RENAME COLUMN FullName    TO full_name;
ALTER TABLE doctors RENAME COLUMN Speciality  TO speciality;
ALTER TABLE doctors RENAME COLUMN ContactNo   TO contact_no;
ALTER TABLE doctors RENAME COLUMN JoinDt      TO join_date;
ALTER TABLE doctors RENAME COLUMN Salary      TO salary_monthly;  -- also clarifies unit
ALTER TABLE doctors RENAME COLUMN isActive    TO is_active;

-- Also standardise appointments table which has mixed casing:
ALTER TABLE appointments RENAME COLUMN appt_id     TO appt_id;     -- already lowercase
ALTER TABLE appointments RENAME COLUMN patient_id  TO patient_id;  -- already lowercase
-- (appointments columns were already mostly snake_case — doctors was the primary offender)

-- Naming convention adopted: lowercase snake_case throughout all tables.
-- Abbreviations expanded: JoinDt → join_date, ContactNo → contact_no.
-- Units clarified where ambiguous: Salary → salary_monthly.
-- This standard must be applied to any new tables added in future migrations.

-- Explanation:
-- Inconsistent Naming forces developers to constantly check the schema
-- before writing queries and causes silent failures when ORM frameworks
-- auto-map column names. By standardising to snake_case, every column
-- is immediately readable, auto-mapping works without configuration
-- overrides, and new developers can contribute without a schema lookup.


-- ------------------------------------------------------------
-- R4: Fix Missing Constraints — billing and appointments (1 Mark)
-- Smell: Missing Keys/Constraints — billing has no PK on bill_no,
--        and no FK links billing→patients or appointments→doctors.
--        Orphan rows can exist silently.
-- Fix:   Add PK to billing, backfill orphans, then add FKs.
-- ------------------------------------------------------------

-- Step 1: Add PRIMARY KEY to billing (bill_no was intended as PK)
ALTER TABLE billing ADD PRIMARY KEY (bill_no);

-- Step 2: Remove orphan billing rows referencing non-existent patients
--         This MUST be done before adding the FK — if orphans exist,
--         the FK addition will fail with a constraint violation error.
DELETE FROM billing
WHERE pid NOT IN (SELECT pid FROM pat_master);

-- Step 3: Add FK from billing to pat_master (patient must exist)
ALTER TABLE billing
    ADD CONSTRAINT fk_billing_patient
        FOREIGN KEY (pid) REFERENCES pat_master(pid);

-- Step 4: Remove orphan appointments referencing non-existent doctors
DELETE FROM appointments
WHERE doc_id NOT IN (SELECT doctor_id FROM doctors);

-- Step 5: Add FK from appointments to doctors (doctor must exist)
ALTER TABLE appointments
    ADD CONSTRAINT fk_appt_doctor
        FOREIGN KEY (doc_id) REFERENCES doctors(doctor_id);

-- Step 6: Add FK from doctors to departments
DELETE FROM doctors
WHERE dept_id NOT IN (SELECT dept_id FROM departments);

ALTER TABLE doctors
    ADD CONSTRAINT fk_doctor_dept
        FOREIGN KEY (dept_id) REFERENCES departments(dept_id);

-- Explanation:
-- The DELETE backfill step before each FK is mandatory because MySQL
-- enforces referential integrity at the moment the constraint is added,
-- not just on future inserts. If any billing row has a pid that does
-- not exist in pat_master, the ALTER TABLE statement will fail with
-- ERROR 1452 (Cannot add or update a child row). The DELETE removes
-- these orphan rows first so the constraint can be applied cleanly.
-- In a production migration you would log these orphan rows to a
-- separate audit table before deleting, rather than discarding them.


-- ------------------------------------------------------------
-- R5: Add Audit Trail to appointments (0.5 Mark)
-- Smell: Lack of Audit Trail — no record of when an appointment
--        was created or last modified. In a hospital, changes to
--        appointment records may be required for medico-legal
--        investigations and regulatory compliance (e.g. HIPAA,
--        Pakistan DPDP Bill requirements).
-- Fix:   Add created_at and updated_at timestamp columns.
--        updated_at auto-refreshes on every UPDATE via trigger.
-- ------------------------------------------------------------

ALTER TABLE appointments
    ADD COLUMN created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN updated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
                            ON UPDATE CURRENT_TIMESTAMP;

-- For MySQL 5.7 and earlier that do not support ON UPDATE in ALTER,
-- use an explicit trigger instead:
DROP TRIGGER IF EXISTS trg_appt_audit;

DELIMITER $$
CREATE TRIGGER trg_appt_audit
BEFORE UPDATE ON appointments
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$
DELIMITER ;

-- Explanation:
-- The Lack of Audit Trail smell means there is no way to determine
-- when an appointment record was created or who last changed it.
-- In a hospital context this is a serious risk: if a patient's
-- appointment time is changed without a trace, there is no evidence
-- for a medico-legal dispute about whether a patient was notified.
-- Regulators in healthcare require an immutable audit history for
-- any changes to patient-facing records. The created_at column
-- captures the insertion timestamp once; updated_at is refreshed
-- automatically on every UPDATE by the trigger, providing a
-- lightweight but enforceable audit trail at the database level.


-- ============================================================
-- F3 — REFACTORING IMPACT SUMMARY PARAGRAPH (write in report)
-- ============================================================
-- Of the five refactorings, R4 (Adding Missing Constraints) delivered
-- the greatest quality improvement per unit of effort.
-- The effort was low — five ALTER TABLE statements and three DELETE
-- backfills — but the benefit is structural and permanent: the database
-- now enforces referential integrity at the engine level, meaning no
-- future application bug, direct SQL insert, or ETL script can ever
-- introduce orphan rows or duplicate bills. This is a one-time fix
-- with zero ongoing maintenance cost. By contrast, R1 (the derived
-- data view) also has high benefit but requires all application queries
-- to be updated to reference v_billing_summary instead of billing.
-- R4 protects the entire schema passively and permanently, making it
-- the highest-value refactoring in this set.
-- ============================================================