# JKH Cloud X-Ray — TEST copy (billing fixes)

This is a **separate test copy** of your live `jkh-cloud-xray` app — its own GitHub
repo, its own Cloudflare Worker (`jkh-cloud-xray-test`), its own D1 database
(`jkh-cloud-xray-test-db`). Nothing here touches your live app's data.

Use this to check the recent billing fixes before they go into the live app:
- Bill number = UHID (extra bills for the same patient = UHID+A, UHID+B, ...)
- UHID (and its linked bill) now stays firm once assigned — editing the visit date
  no longer silently generates a new UHID

## Set up the test environment

1. **New GitHub repo** — e.g. `jkh-cloud-xray-test`. Upload every file from this
   project into it (drag-and-drop via "Add file → Upload files").

2. **New D1 database:**
   - Cloudflare dashboard → Workers & Pages → D1 → Create Database
   - Name it `jkh-cloud-xray-test-db`
   - Copy the Database ID it gives you

3. **Update `wrangler.toml`** on GitHub: replace `PASTE_YOUR_NEW_DATABASE_ID_HERE`
   with that ID. Commit.

4. **Connect the repo to a new Cloudflare Worker:**
   - Workers & Pages → Create → Workers → **Import a repository**
   - Pick your new `jkh-cloud-xray-test` repo
   - This creates a new Worker (`jkh-cloud-xray-test`), separate from your live one

5. **Create the tables:** D1 → jkh-cloud-xray-test-db → Console. Run each statement
   in `schema.sql` **one at a time** (the Console often fails on multiple
   `CREATE TABLE` statements pasted together).

6. **Load starter data:** same Console — paste and run `seed_procedures.sql`, then
   `seed_medicines.sql`.

7. Visit your new Worker's URL (something like
   `https://jkh-cloud-xray-test.<yoursubdomain>.workers.dev`) — should show the OPD
   form, empty (no real patient data).

## Test these specifically

- Create a test patient → confirm a bill auto-appears with number = UHID
- Change the visit date field afterward → confirm the UHID does **not** change
- Click "＋ New Bill for this Patient" a couple of times → confirm bill numbers
  come out as UHID+A, UHID+B, ...
- Add procedures + a part-payment on a bill → confirm balance/status look right

Report anything odd and it'll get fixed here first — nothing moves to your live app
until you confirm it's working.
