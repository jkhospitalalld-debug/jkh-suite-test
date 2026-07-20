import { Hono } from 'hono';
import { cors } from 'hono/cors';

const app = new Hono();

// Public - no login required (matches how the clinic actually uses this).
app.use('*', cors());

app.get('/api/health', (c) => c.json({ ok: true, service: 'jkh-dental-suite' }));

/* =========================================================
   MASTER PROCEDURE LIST (shared by OPD form + Billing)
   ========================================================= */

app.get('/api/procedures', async (c) => {
  const { results } = await c.env.DB.prepare('SELECT code, name, rate FROM master_procedures ORDER BY code').all();
  return c.json(results);
});

// Add new or update existing (matched by code)
app.post('/api/procedures', async (c) => {
  const { code, name, rate } = await c.req.json();
  if (!code || !name) return c.json({ error: 'code and name are required' }, 400);
  await c.env.DB.prepare(
    `INSERT INTO master_procedures (code, name, rate) VALUES (?,?,?)
     ON CONFLICT(code) DO UPDATE SET name=excluded.name, rate=excluded.rate`
  ).bind(code.trim(), name.trim(), parseFloat(rate) || 0).run();
  return c.json({ ok: true });
});

app.delete('/api/procedures/:code', async (c) => {
  await c.env.DB.prepare('DELETE FROM master_procedures WHERE code = ?').bind(c.req.param('code')).run();
  return c.json({ ok: true });
});

/* =========================================================
   MASTER MEDICINE LIST (OPD form's prescription dropdown)
   ========================================================= */

app.get('/api/medicines', async (c) => {
  const { results } = await c.env.DB.prepare('SELECT id, category, name FROM master_medicines ORDER BY category, name').all();
  return c.json(results);
});

app.post('/api/medicines', async (c) => {
  const { category, name } = await c.req.json();
  if (!category || !name) return c.json({ error: 'category and name are required' }, 400);
  await c.env.DB.prepare('INSERT INTO master_medicines (category, name) VALUES (?,?)').bind(category.trim(), name.trim()).run();
  return c.json({ ok: true });
});

app.delete('/api/medicines/:id', async (c) => {
  await c.env.DB.prepare('DELETE FROM master_medicines WHERE id = ?').bind(c.req.param('id')).run();
  return c.json({ ok: true });
});

/* =========================================================
   PATIENTS (OPD form)
   ========================================================= */

app.get('/api/patients', async (c) => {
  const { results } = await c.env.DB
    .prepare('SELECT id, data, created_at, updated_at FROM patients ORDER BY created_at DESC')
    .all();
  const patients = results.map((r) => ({ id: r.id, created_at: r.created_at, updated_at: r.updated_at, ...JSON.parse(r.data) }));
  return c.json(patients);
});

app.get('/api/patients/:id', async (c) => {
  const id = c.req.param('id');
  const row = await c.env.DB.prepare('SELECT id, data, created_at, updated_at FROM patients WHERE id = ?').bind(id).first();
  if (!row) return c.json({ error: 'Not found' }, 404);
  return c.json({ id: row.id, created_at: row.created_at, updated_at: row.updated_at, ...JSON.parse(row.data) });
});

app.post('/api/patients', async (c) => {
  const body = await c.req.json();
  if (!body.id) return c.json({ error: 'Missing id (UHID)' }, 400);
  const now = new Date().toISOString();
  const name = body.form?.name || '';
  const date = body.form?.date || '';
  const data = JSON.stringify({ form: body.form || {}, items: body.items || [], meds: body.meds || [], visits: body.visits || [] });
  await c.env.DB.prepare(
    `INSERT INTO patients (id, name, date, data, created_at, updated_at) VALUES (?,?,?,?,?,?)
     ON CONFLICT(id) DO UPDATE SET name=excluded.name, date=excluded.date, data=excluded.data, updated_at=excluded.updated_at`
  ).bind(body.id, name, date, data, now, now).run();
  return c.json({ ok: true, id: body.id, updated_at: now });
});

app.post('/api/patients/bulk', async (c) => {
  const arr = await c.req.json();
  if (!Array.isArray(arr)) return c.json({ error: 'Expected an array of patients' }, 400);
  const now = new Date().toISOString();
  const stmt = c.env.DB.prepare(
    `INSERT INTO patients (id, name, date, data, created_at, updated_at) VALUES (?,?,?,?,?,?)
     ON CONFLICT(id) DO UPDATE SET name=excluded.name, date=excluded.date, data=excluded.data, updated_at=excluded.updated_at`
  );
  const batch = arr.filter((p) => p.id).map((p) => stmt.bind(
    p.id, p.form?.name || '', p.form?.date || '',
    JSON.stringify({ form: p.form || {}, items: p.items || [], meds: p.meds || [], visits: p.visits || [] }),
    now, now
  ));
  if (batch.length) await c.env.DB.batch(batch);
  return c.json({ ok: true, count: batch.length });
});

app.delete('/api/patients/:id', async (c) => {
  await c.env.DB.prepare('DELETE FROM patients WHERE id = ?').bind(c.req.param('id')).run();
  return c.json({ ok: true });
});

// Shared UHID counter - so two devices never generate the same UHID.
// Format: YYYYMMDD + system letter + 4-digit counter, counter resets each day.
app.get('/api/next-uhid', async (c) => {
  const dateVal = c.req.query('date') || new Date().toISOString().slice(0, 10);
  const system = c.req.query('system') || 'M';
  const bill = (c.req.query('bill') || '').trim();
  const d = new Date(dateVal);
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  const dayKey = `${yyyy}${mm}${dd}`;

  if (bill) {
    const numeric = /^\d+$/.test(bill);
    const last = numeric ? String(bill).padStart(4, '0') : bill.replace(/\s+/g, '-');
    return c.json({ uhid: `${dayKey}${system}${last}` });
  }

  await c.env.DB.prepare(
    `INSERT INTO uhid_counters (month_key, counter) VALUES (?, 1)
     ON CONFLICT(month_key) DO UPDATE SET counter = counter + 1`
  ).bind(dayKey).run();
  const row = await c.env.DB.prepare('SELECT counter FROM uhid_counters WHERE month_key = ?').bind(dayKey).first();
  return c.json({ uhid: `${dayKey}${system}${String(row.counter).padStart(4, '0')}` });
});

/* =========================================================
   BILLING
   ========================================================= */

app.get('/api/bills', async (c) => {
  const includeTrash = c.req.query('trash') === '1';
  const { results } = await c.env.DB
    .prepare('SELECT no, data, deleted, updated_at FROM bills WHERE deleted = ? ORDER BY updated_at DESC')
    .bind(includeTrash ? 1 : 0)
    .all();
  const bills = results.map((r) => ({ ...JSON.parse(r.data), no: r.no, updated_at: r.updated_at }));
  return c.json(bills);
});

// GET /api/bills/by-patient/:uhid - find bill(s) linked to a specific OPD patient
app.get('/api/bills/by-patient/:uhid', async (c) => {
  const uhid = c.req.param('uhid');
  const { results } = await c.env.DB
    .prepare('SELECT no, data, updated_at FROM bills WHERE deleted = 0 ORDER BY updated_at DESC')
    .all();
  const bills = results
    .map((r) => ({ ...JSON.parse(r.data), no: r.no, updated_at: r.updated_at }))
    .filter((b) => b.patientUHID === uhid);
  return c.json(bills);
});

app.post('/api/bills', async (c) => {
  const bill = await c.req.json();
  if (!bill.no) return c.json({ error: 'Missing bill no' }, 400);
  const now = new Date().toISOString();
  await c.env.DB.prepare(
    `INSERT INTO bills (no, name, date, data, deleted, updated_at) VALUES (?,?,?,?,0,?)
     ON CONFLICT(no) DO UPDATE SET name=excluded.name, date=excluded.date, data=excluded.data, deleted=0, updated_at=excluded.updated_at`
  ).bind(bill.no, bill.name || '', bill.date || '', JSON.stringify(bill), now).run();
  return c.json({ ok: true, no: bill.no, updated_at: now });
});

// Soft delete (move to trash) / restore
app.post('/api/bills/:no/trash', async (c) => {
  await c.env.DB.prepare('UPDATE bills SET deleted = 1, updated_at = ? WHERE no = ?')
    .bind(new Date().toISOString(), c.req.param('no')).run();
  return c.json({ ok: true });
});
app.post('/api/bills/:no/restore', async (c) => {
  await c.env.DB.prepare('UPDATE bills SET deleted = 0, updated_at = ? WHERE no = ?')
    .bind(new Date().toISOString(), c.req.param('no')).run();
  return c.json({ ok: true });
});
// Permanent delete
app.delete('/api/bills/:no', async (c) => {
  await c.env.DB.prepare('DELETE FROM bills WHERE no = ?').bind(c.req.param('no')).run();
  return c.json({ ok: true });
});

// Shared bill-number counter - so two devices never generate the same bill number.
// Format: YYMMDD + 4-digit counter, counter resets each day.
app.get('/api/next-billno', async (c) => {
  const dayKey = new Date().toISOString().slice(2, 10).replace(/-/g, ''); // e.g. 260713
  await c.env.DB.prepare(
    `INSERT INTO bill_counters (month_key, counter) VALUES (?, 1)
     ON CONFLICT(month_key) DO UPDATE SET counter = counter + 1`
  ).bind(dayKey).run();
  const row = await c.env.DB.prepare('SELECT counter FROM bill_counters WHERE month_key = ?').bind(dayKey).first();
  return c.json({ no: dayKey + String(row.counter).padStart(4, '0') });
});

// Anything that isn't an /api/* route falls through to the static frontend files in public/.
app.notFound((c) => c.env.ASSETS.fetch(c.req.raw));

export default app;
