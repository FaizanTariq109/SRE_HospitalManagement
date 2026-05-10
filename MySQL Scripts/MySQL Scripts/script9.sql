USE healthbridge;

-- Insert sample departments first (doctors FK depends on it)
INSERT INTO departments (dept_id, dept_nm, hod, budget) VALUES
(1, 'General Medicine', 'Dr. Ahmed Khan', 500000),
(2, 'Gynaecology', 'Dr. Sara Ali', 600000);

-- Insert the two doctors referenced in the CSV
INSERT INTO doctors 
(doctor_id, full_name, speciality, contact_no, join_date, salary_monthly, dept_id, is_active)
VALUES
(7,  'Dr. Ayesha Noor',  'Gynaecology',      '0300-1234567', '2015-03-01', 150000, 2, 'Y'),
(12, 'Dr. Kamran Raza',  'General Medicine', '0300-9876543', '2012-06-01', 180000, 1, 'Y');