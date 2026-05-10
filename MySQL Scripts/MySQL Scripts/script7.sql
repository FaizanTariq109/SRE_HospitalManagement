USE healthbridge;

-- R5: Add audit trail columns to appointments
ALTER TABLE appointments
    ADD COLUMN created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
                           ON UPDATE CURRENT_TIMESTAMP;

-- Trigger to auto-refresh updated_at on every UPDATE
DROP TRIGGER IF EXISTS trg_appt_audit;

CREATE TRIGGER trg_appt_audit
BEFORE UPDATE ON appointments
FOR EACH ROW
    SET NEW.updated_at = NOW();