USE healthbridge;

-- Insert the patients referenced in the CSV
INSERT INTO pat_master (pid, p_name, dob, sex) VALUES
(2,  'Zara Hussain',  '01/01/1995', 'F'),
(3,  'Usman Khan',   '15/03/1990', 'M'),
(5,  'Ali Hassan',   '20/05/1988', 'M'),
(6,  'Sana Mirza',   '12/08/1992', 'F'),
(8,  'Sara Malik',   '05/11/1993', 'F'),
(9,  'Ahmed Raza',   '22/07/1985', 'M'),
(14, 'Fatima Zahra', '30/09/1997', 'F'),
(17, 'Bilal Mahmood','10/02/1991', 'M'),
(21, 'Hina Iqbal',   '18/06/1989', 'F');