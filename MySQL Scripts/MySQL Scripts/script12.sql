USE healthbridge;

SELECT COUNT(*) AS orphans FROM appointments a
LEFT JOIN pat_master p ON a.patient_id = p.pid
WHERE p.pid IS NULL;