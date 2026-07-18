PRAGMA foreign_keys = ON;

------------------------------------------------------------
-- PATIENTS
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS patients (
    id TEXT PRIMARY KEY,              -- UHID
    name TEXT NOT NULL,
    phone TEXT,
    age TEXT,
    sex TEXT,
    dob TEXT,
    address TEXT,

    first_visit TEXT,
    last_visit TEXT,

    data TEXT NOT NULL,               -- JSON (medical details)

    deleted INTEGER NOT NULL DEFAULT 0,

    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_patients_name
ON patients(name);

CREATE INDEX IF NOT EXISTS idx_patients_phone
ON patients(phone);

CREATE INDEX IF NOT EXISTS idx_patients_last_visit
ON patients(last_visit);

------------------------------------------------------------
-- VISITS
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS visits (

    visit_id TEXT PRIMARY KEY,

    patient_id TEXT NOT NULL,

    visit_date TEXT NOT NULL,

    doctor TEXT,

    data TEXT NOT NULL,

    created_at TEXT NOT NULL,

    FOREIGN KEY(patient_id)
    REFERENCES patients(id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_visit_patient
ON visits(patient_id);

CREATE INDEX IF NOT EXISTS idx_visit_date
ON visits(visit_date);

------------------------------------------------------------
-- MASTER PROCEDURES
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS master_procedures (

    code TEXT PRIMARY KEY,

    name TEXT NOT NULL,

    category TEXT,

    rate REAL NOT NULL DEFAULT 0,

    active INTEGER DEFAULT 1
);

------------------------------------------------------------
-- MASTER MEDICINES
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS master_medicines (

    id INTEGER PRIMARY KEY AUTOINCREMENT,

    name TEXT NOT NULL,

    dose TEXT,

    instruction TEXT,

    active INTEGER DEFAULT 1
);

------------------------------------------------------------
-- BILLS
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS bills (

    no TEXT PRIMARY KEY,

    patient_id TEXT,

    name TEXT,

    phone TEXT,

    bill_date TEXT,

    total REAL DEFAULT 0,

    discount REAL DEFAULT 0,

    paid REAL DEFAULT 0,

    balance REAL DEFAULT 0,

    deleted INTEGER DEFAULT 0,

    data TEXT NOT NULL,

    updated_at TEXT NOT NULL,

    FOREIGN KEY(patient_id)
    REFERENCES patients(id)
);

CREATE INDEX IF NOT EXISTS idx_bill_name
ON bills(name);

CREATE INDEX IF NOT EXISTS idx_bill_date
ON bills(bill_date);

------------------------------------------------------------
-- PAYMENTS
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payments (

    payment_id TEXT PRIMARY KEY,

    bill_no TEXT NOT NULL,

    amount REAL NOT NULL,

    payment_mode TEXT,

    payment_date TEXT,

    remarks TEXT,

    FOREIGN KEY(bill_no)
    REFERENCES bills(no)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_payment_bill
ON payments(bill_no);

------------------------------------------------------------
-- XRAY / IMAGE STORAGE
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS images (

    id TEXT PRIMARY KEY,

    patient_id TEXT NOT NULL,

    visit_id TEXT,

    image_type TEXT,

    filename TEXT,

    file_url TEXT,

    uploaded_at TEXT,

    FOREIGN KEY(patient_id)
    REFERENCES patients(id)
);

------------------------------------------------------------
-- USERS
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (

    username TEXT PRIMARY KEY,

    fullname TEXT,

    role TEXT,

    password_hash TEXT,

    active INTEGER DEFAULT 1
);

------------------------------------------------------------
-- SETTINGS
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS settings (

    key TEXT PRIMARY KEY,

    value TEXT
);

------------------------------------------------------------
-- UHID COUNTERS
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS uhid_counters (

    month_key TEXT PRIMARY KEY,

    counter INTEGER NOT NULL DEFAULT 0
);

------------------------------------------------------------
-- BILL COUNTERS
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS bill_counters (

    month_key TEXT PRIMARY KEY,

    counter INTEGER NOT NULL DEFAULT 0
);

------------------------------------------------------------
-- AUDIT LOG
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_log (

    id INTEGER PRIMARY KEY AUTOINCREMENT,

    table_name TEXT,

    record_id TEXT,

    action TEXT,

    username TEXT,

    action_time TEXT,

    old_data TEXT,

    new_data TEXT
);

------------------------------------------------------------
-- DEFAULT SETTINGS
------------------------------------------------------------
INSERT OR IGNORE INTO settings(key,value)
VALUES
('clinic_name','J K Hospital Dental Care Center'),
('clinic_phone',''),
('clinic_address',''),
('doctor_name',''),
('bill_prefix','JK'),
('currency','INR');
