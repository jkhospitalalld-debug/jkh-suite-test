# JKH Suite — TEST environment

This is a **completely separate copy** of your app — different GitHub repo, different
Cloudflare Worker, different D1 database. Nothing here can affect your live app
(currently running as Worker `jkh-suite-db`). Use this to try out the new shared
procedure list feature safely before touching real patient/billing data.

## What's different from your live app

- One shared procedure list (`master_procedures` table) used by both the OPD form and
  Billing, instead of two separate hardcoded lists that could drift apart
- A **"⚙ Procedures"** button on the Billing page to add/edit/delete procedures from
  inside the app — no more GitHub editing for this
- Includes all 135 procedures from your current Billing page, including your JK001–JK018
  custom additions
- **New: X-Ray images on the OPD form** — "📷 Add X-Ray" button, works with your phone's
  or computer's camera or gallery, auto-compresses before saving, shows a thumbnail
  gallery per patient, click a thumbnail to view full-size, ✕ to delete. **Images are
  saved locally in the browser on whichever computer you're using (via IndexedDB) — not
  in the cloud database.** This matches your workflow: X-rays only needed in-clinic, so
  no cloud storage service (and no card requirement) needed for this. Note: an X-ray
  saved on the clinic computer will only show up on that same computer/browser, not on
  other devices — this is intentional given how you described using them.
- **New: "⚙ Medicines" button on the OPD form** — add or delete medicines (and even
  whole new categories) from inside the app, same idea as the Procedures manager.
  Includes all 51 medicines from your current form as a starting point.

## 1. Set up the test environment

1. **New GitHub repo** — e.g. name it `jkh-suite-test`. Upload every file from this
   project into it (drag-and-drop all files/folders via "Add file → Upload files").

2. **New D1 database:**
   - Cloudflare dashboard → Workers & Pages → D1 → Create Database
   - Name it `jkh-suite-test-db` (matches what's already set in `wrangler.toml`)
   - Copy the Database ID it gives you

3. **Update `wrangler.toml`** on GitHub: replace `PASTE_YOUR_DATABASE_ID_HERE` with
   that ID. Commit.

4. **Connect the repo to a new Cloudflare Worker:**
   - Workers & Pages → Create → Workers → **Import a repository**
   - Pick your new `jkh-suite-test` repo
   - This creates a new Worker, separate from your live one

5. **Create the tables:** D1 → jkh-suite-test-db → Console. The D1 Console often fails
   if you paste multiple `CREATE TABLE` statements at once — run each statement in
   `schema.sql` **one at a time** (copy one block, run, clear, copy the next, repeat).

6. **Load the procedure list:** same Console, paste in the full contents of
   `seed_procedures.sql`, run it. (This loads all 135 procedures — including your
   custom JK ones — into the new shared table.)

6b. **Load the medicine list:** same Console, paste in the full contents of
   `seed_medicines.sql`, run it. (Loads all 51 medicines from your current form.)

7. Visit your new Worker's URL (something like
   `https://jkh-suite-test.<yoursubdomain>.workers.dev`) — should show the OPD form,
   with test data only (empty patients/bills to start).

## 2. Test it thoroughly

Things worth checking:
- Create a test patient, add procedures, save — confirm it syncs
- Click Billing from that patient — confirm it links correctly, procedures list matches
- Open "⚙ Procedures" — try adding, editing, deleting a procedure — confirm it shows
  up in both the OPD form's Master List and Billing's dropdown afterward
- Add a part-payment, check the balance/status badge
- Try the Register, PDF export, Import Backup — whatever matters most to your workflow

Report anything odd back here and we'll fix it in this test copy before touching your
real data.

## 3. Once confirmed — migrating real data over

When you're happy with the test copy, come back and tell me. We'll do this carefully:

1. Export your **live app's** patients and bills as JSON backups (using the existing
   Export Backup buttons on each page)
2. Import those backups into this test app (which then effectively becomes your new
   live app) — or, if you'd rather keep the same URL your staff already use, we instead
   apply just the *code changes* (not a new repo/database) to your current live app,
   now that we know they work.

We'll decide together which of those two paths makes more sense once testing is done —
no data gets moved until you say so.

       
