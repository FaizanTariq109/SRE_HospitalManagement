USE healthbridge;

-- Step 1: Add PRIMARY KEY to pat_master.pid (it was missing)
ALTER TABLE pat_master ADD PRIMARY KEY (pid);

-- Step 2: Now add FK from billing to pat_master
ALTER TABLE billing
    ADD CONSTRAINT fk_billing_patient
        FOREIGN KEY (pid) REFERENCES pat_master(pid);

-- Step 3: Remove orphan appointments
SET SQL_SAFE_UPDATES = 0;
DELETE FROM appointments
WHERE doc_id NOT IN (SELECT doctor_id FROM doctors);
SET SQL_SAFE_UPDATES = 1;

-- Step 4: Add FK from appointments to doctors
ALTER TABLE appointments
    ADD CONSTRAINT fk_appt_doctor
        FOREIGN KEY (doc_id) REFERENCES doctors(doctor_id);

-- Step 5: Remove orphan doctors
SET SQL_SAFE_UPDATES = 0;
DELETE FROM doctors
WHERE dept_id NOT IN (SELECT dept_id FROM departments);
SET SQL_SAFE_UPDATES = 1;

-- Step 6: Add FK from doctors to departments
ALTER TABLE doctors
    ADD CONSTRAINT fk_doctor_dept
        FOREIGN KEY (dept_id) REFERENCES departments(dept_id);