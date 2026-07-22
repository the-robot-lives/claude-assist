# Backfill — listmonk subscribers → foryou (US-093)

**Do NOT run this during provisioning or repoint.** Backfill runs *after* the
Lists are provisioned and the site forms are repointed, once we have a fresh
listmonk export. Documented here; executed manually by the lead + user.

## Mechanism

foryou exposes a management import endpoint (Chunk B, `ListmonkImportWorker`):

```
POST https://foryou.therobotlives.com/api/v1/management/lists/:id/signups/import
Authorization: <management api key>
Content-Type: application/json

{ "rows": [ { "email": "a@b.com", "attribs": {...}, "status": "subscribed" }, ... ] }
```

Behavior (from `Foryou.Workers.ListmonkImportWorker`):
- Enqueued on **Oban** — returns `202 { accepted: true, job_id, rows }` immediately.
- **Dedupes** by `(list_id, email)` — re-importing is safe.
- **Never overwrites an unsubscribed record** — a subscriber who opted out in
  listmonk stays opted out.
- **Sends no opt-in / confirmation emails** — imported subscribers are treated as
  already-confirmed; nobody gets re-spammed on migration.

## Per-list procedure

For each site List in `README.md`:

1. **Export from listmonk** — in the listmonk admin (or API), export the
   subscribers of the corresponding list UUID (the "prior listmonk list UUID"
   column) as CSV/JSON. Columns needed: `email`, subscription `status`, any
   attribs.
2. **Map to foryou rows** — one JSON object per subscriber:
   `{ "email", "status": "subscribed"|"unsubscribed", "attribs": { ...typed by attr slug } }`.
   For the email-only waitlists, `attribs` is `{}`; email is the identity.
3. **Resolve the foryou List `id`** — `GET /api/v1/management/lists?project_id=<uuid>`
   and match by `public_slug`, or `GET /api/v1/management/lists/<id>`.
4. **POST the import** (batch, e.g. ≤1000 rows/call) to the import endpoint above.
5. **Verify** — `GET /api/v1/management/lists/:id/signups?format=csv` and compare
   counts against the listmonk export.

## Lists in scope

All eight waitlist lists in `README.md` (therobotlives, codefresh, gotta-cc,
aifighter, robots-unite, jailbreaking, noizurpg, iotgo). `noizu-contact` is new
(no listmonk predecessor) — nothing to backfill.

## Order of operations for the whole cutover

1. Provision Lists (`provision-lists.sh --apply` or `terraform apply`).
2. Deploy the repointed site frontends (new signups now land in foryou).
3. Export listmonk + run this backfill (historical subscribers land in foryou).
4. (Chunk H, separate) decommission listmonk once parity is confirmed.
