USE healthbridge;

-- V1: Total rows migrated
SELECT COUNT(*) AS migrated_rows FROM appointments;

-- V2: No NULL datetime values (T1 worked for every row)
SELECT COUNT(*) AS null_dates FROM appointments WHERE appt_datetime IS NULL;

-- V3: Only valid status codes exist (T4 filtered invalid codes)
SELECT DISTINCT status FROM appointments;

-- V4: No orphan appointments (patient_id must exist in pat_master)
SELECT COUNT(*) AS orphans FROM appointments a
LEFT JOIN pat_master p ON a.patient_id = p.pid
WHERE p.pid IS NULL;