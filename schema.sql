-- Patients (OPD form)
CREATE TABLE IF NOT EXISTS patients (
  id TEXT PRIMARY KEY,      -- UHID, e.g. 20260713M0001
  name TEXT,
  date TEXT,
  data TEXT NOT NULL,       -- JSON blob: { form, items, meds, visits }
  created_at TEXT,          -- set once, never changed after that
  updated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_patients_name ON patients(name);
CREATE INDEX IF NOT EXISTS idx_patients_date ON patients(date);

-- Shared UHID counter (prevents two devices generating the same UHID)
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

-- Bills (billing page)
CREATE TABLE IF NOT EXISTS bills (
  no TEXT PRIMARY KEY,      -- Bill number, e.g. 260700001
  name TEXT,
  date TEXT,
  data TEXT NOT NULL,       -- JSON blob: full bill (name, age, sex, phone, lines, total, etc.)
  deleted INTEGER NOT NULL DEFAULT 0,  -- 1 = in trash
  updated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_bills_name ON bills(name);
CREATE INDEX IF NOT EXISTS idx_bills_date ON bills(date);

-- Shared bill number counter (prevents two devices generating the same bill number)
CREATE TABLE IF NOT EXISTS bill_counters (
  month_key TEXT PRIMARY KEY,
  counter INTEGER NOT NULL DEFAULT 0
);
