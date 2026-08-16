CREATE TABLE IF NOT EXISTS patients (
  id TEXT PRIMARY KEY,
  name TEXT,
  date TEXT,
  data TEXT NOT NULL, 
  created_at TEXT,   
  updated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_patients_name ON patients(name);
CREATE INDEX IF NOT EXISTS idx_patients_date ON patients(date);


CREATE TABLE IF NOT EXISTS uhid_counters (
  month_key TEXT PRIMARY KEY,
  counter INTEGER NOT NULL DEFAULT 0
);

-- Shared master procedure list (used by both OPD form and Billing)
CREATE TABLE IF NOT EXISTS master_procedures (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  rate REAL NOT NULL DEFAULT 0
);

-- Shared master medicine list (used by OPD form's prescription dropdown)
CREATE TABLE IF NOT EXISTS master_medicines (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT NOT NULL,
  name TEXT NOT NULL
);


CREATE TABLE IF NOT EXISTS bills (
  no TEXT PRIMARY KEY, 
  name TEXT,
  date TEXT,
  data TEXT NOT NULL,
  deleted INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_bills_name ON bills(name);
CREATE INDEX IF NOT EXISTS idx_bills_date ON bills(date);


CREATE TABLE IF NOT EXISTS bill_counters (
  month_key TEXT PRIMARY KEY,
  counter INTEGER NOT NULL DEFAULT 0
);

-- X-ray images, stored as base64 in D1 (one row per image, per patient UHID)
CREATE TABLE IF NOT EXISTS xray_images (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uhid TEXT NOT NULL,
  filename TEXT,
  data TEXT NOT NULL,
  uploaded_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_xray_images_uhid ON xray_images(uhid);
