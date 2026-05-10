# migration_etl.py
# SOFTWARE RE-ENGINEERING FINAL PROJECT
# Geeti Fatima (22F-3704) & Faizan Tariq (22F-3714)
# Part G — ETL Transformation Script
# Migrates legacy appointments CSV into refactored appointments table

import csv
import mysql.connector
from datetime import datetime

# -------------------------------------------------------
# Valid status codes — anything else is logged and skipped
# T4: Validate each status against appt_status_ref
# -------------------------------------------------------
VALID_STATUSES = {'P', 'C', 'X', 'H', 'R'}

# -------------------------------------------------------
# T1: Convert appt_date from 'DD/MM/YYYY HH:MM' to DATETIME
# The legacy system stored dates as plain text in this format
# MySQL DATETIME requires 'YYYY-MM-DD HH:MM:SS'
# -------------------------------------------------------
def parse_appt_date(raw):
    raw = raw.strip()  # remove any accidental whitespace
    try:
        # Parse the legacy format 'DD/MM/YYYY HH:MM'
        dt = datetime.strptime(raw, '%d/%m/%Y %H:%M')
        return dt  # mysql.connector accepts datetime objects directly
    except ValueError:
        # If format is wrong, return None — row will be skipped
        print(f'  [WARNING] Could not parse date: "{raw}" — row will be skipped')
        return None

# -------------------------------------------------------
# T2: Split room column into room_number and building_block
# Legacy format: 'Room 3 Block B'
# Target:        room_number=3, building_block='Block B'
# -------------------------------------------------------
def split_room(raw):
    raw = raw.strip()
    try:
        # Split on spaces: ['Room', '3', 'Block', 'B']
        parts = raw.split()
        # parts[1] is the room number integer
        room_no = int(parts[1])
        # parts[2] onward is the block e.g. 'Block B'
        block = ' '.join(parts[2:])
        return room_no, block
    except (IndexError, ValueError):
        # If format is unexpected, return safe defaults
        print(f'  [WARNING] Could not parse room: "{raw}" — using defaults')
        return None, raw  # keep raw value in building_block for review

# -------------------------------------------------------
# MAIN MIGRATION FUNCTION
# -------------------------------------------------------
def migrate(csv_path, db_config):

    # Connect to MySQL
    print('Connecting to MySQL...')
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()
    print('Connected successfully.\n')

    # Counters for reporting
    inserted = 0
    skipped  = []

    # Open the legacy CSV file
    with open(csv_path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)

        for row in reader:
            appt_id = row['appt_id']

            # -------------------------------------------
            # T4: Validate status — skip unknown codes
            # -------------------------------------------
            if row['status'] not in VALID_STATUSES:
                print(f'  [SKIPPED] appt_id={appt_id} — invalid status "{row["status"]}"')
                skipped.append(appt_id)
                continue

            # -------------------------------------------
            # T1: Parse date from text to DATETIME
            # -------------------------------------------
            appt_dt = parse_appt_date(row['appt_date'])
            if appt_dt is None:
                print(f'  [SKIPPED] appt_id={appt_id} — unparseable date')
                skipped.append(appt_id)
                continue

            # -------------------------------------------
            # T2: Split room into number and block
            # -------------------------------------------
            room_no, block = split_room(row['room'])

            # -------------------------------------------
            # T3: patient_nm, patient_ph, doc_name are
            #     intentionally OMITTED from the INSERT
            #     They are now derived via FK joins on
            #     patient_id → patients and doc_id → doctors
            #     net_fee is also omitted — derived as fee-discount
            # -------------------------------------------
            try:
                cursor.execute(
                    '''
                    INSERT INTO appointments
                        (appt_id, patient_id, doc_id, appt_datetime,
                         status, fee, discount,
                         room_number, building_block)
                    VALUES
                        (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ''',
                    (
                        appt_id,
                        row['patient_id'],
                        row['doc_id'],
                        appt_dt,              # T1 — proper DATETIME
                        row['status'],        # T4 — already validated
                        row['fee'],
                        row['discount'],
                        room_no,              # T2 — split room number
                        block                 # T2 — split block name
                    )
                )
                inserted += 1
                print(f'  [OK] appt_id={appt_id} inserted successfully')

            except mysql.connector.Error as err:
                print(f'  [ERROR] appt_id={appt_id} — DB error: {err}')
                skipped.append(appt_id)
                continue

    # Commit all inserts at once
    conn.commit()
    print('\n========================================')
    print(f'Migration complete.')
    print(f'  Rows inserted : {inserted}')
    print(f'  Rows skipped  : {len(skipped)}')
    if skipped:
        print(f'  Skipped IDs   : {skipped}')
    print('========================================')

    cursor.close()
    conn.close()


# -------------------------------------------------------
# CONFIGURATION — update password if yours is different
# -------------------------------------------------------
if __name__ == '__main__':

    DB_CONFIG = {
        'host'    : 'localhost',
        'user'    : 'root',
        'password': 'MyNewPass123!',       
        'database': 'healthbridge'
    }

    # Path to your CSV file on Desktop
    # If your Windows username is different, update the path below
    import os
    CSV_PATH = os.path.join(os.path.expanduser('~'), 'OneDrive', 'Desktop', 'appointments.csv')

    migrate(CSV_PATH, DB_CONFIG)
