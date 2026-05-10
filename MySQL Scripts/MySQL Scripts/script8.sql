USE healthbridge;

-- Add refactored columns needed by the ETL script
ALTER TABLE appointments
    ADD COLUMN appt_datetime   DATETIME        NULL,
    ADD COLUMN room_number     INT             NULL,
    ADD COLUMN building_block  VARCHAR(50)     NULL;