# foryou — Cross-chunk decisions (from PRD review)

Authoritative resolutions to the open questions raised by the PRD agents (`prd-b/c/d/e`).
Impl agents MUST follow these. Date: 2026-07-22.

## D1 — Chunk B owns the FULL List/Signup API surface  *(resolves prd-c A1, prd-d Q1)*
Chunk B (M1) implements every list-domain endpoint each consumer needs — not just the public POST:
- **Public** (widget + external sites): `GET /api/v1/public/services/:svc/lists/:list` (manifest read — widget fetches the attribute schema at runtime) + `POST /api/v1/public/services/:svc/lists/:list/signups` (always-202, no-leak) + token confirm/unsubscribe.
- **JWT PBAC project-scoped** (admin console): `GET /organizations/:org_id/projects/:project_id/lists`, `GET /lists/:id/signups` (paginated), list/signup detail — `Authz.check_permission(uid,"project",project_id,"list:view|...")`.
- **Management** (api-key; TF provider + backfill): `Management.ListsController` modeled on the existing `Management.FormsController` — CRUD + `GET .../signups` export + `POST .../signups/import`.
- **Self-service** (pref center): `/me/signups`, `/me/inquiries`, `DELETE /me/signups/:id`.

## D2 — No-leak posture  *(prd-c A2)*: always-202-and-silently-drop
Public signup returns 202 for any well-formed request (even if already subscribed / soft-fail) and silently drops. Only 4xx for malformed email/slug. Strongest anti-enumeration.

## D3 — CORS  *(prd-c A3)*: env-floor for M2; DB-backed dynamic allowlist is a fast-follow
M2/M3 use the env-floor `CORS_ORIGINS` (configured in M0). The dynamic DB-backed allowlist (US-018, "without redeploy") is deferred. Note: the **iframe** widget variant is same-origin → needs NO CORS; only the **script** variant's cross-origin fetch depends on `CORS_ORIGINS`.

## D4 — `signups.attribs` GIN index  *(prd-d Q5)*: include in Chunk B schema
Add `CREATE INDEX ON signups USING GIN (attribs)` in the Chunk B lists/signups changelog (attribute-value search in the admin console).

## D5 — CSV export  *(prd-d Q2)*: RFC-4180, UTF-8 w/ BOM, one column per declared attribute
Streamed; honors active filters; standard columns (email, name, status, source, created_at) + one column per declared list attribute. Match the management backfill export column-for-column where sensible.

## D6 — Pagination  *(prd-d Q6)*: offset/limit for M3; keyset post-backfill
Offset/limit default is fine for M3 (<~50k/list). Revisit keyset pagination after listmonk backfill (Chunk G).

## D7 — Inquiries project-linking  *(prd-d Q3)*: deferred to Chunk F (M4)
Inquiries are flat today (no project_id). M3 admin shows them flat with `source` only. Project-linking inquiries to a service/list is Chunk F scope.

## D8 — listmonk UUID discrepancy  *(prd-c A4)*: re-verify per-site at Chunk G
The original listmonk recon's per-site UUID table is **UNTRUSTED** — e.g. `projects/therobotlives.com/app/frontend/src/app/waitlist-form.tsx:6` actually hardcodes `ff9aca9d-…` (which the table attributed to gotta.cc). At Chunk G cutover, **grep each site's form** to confirm the real list UUID before backfill; do not trust the recon table.

## D9 — Legacy inquiries in `/me/inquiries`  *(prd-e Q1)*: UNION by email + `source:"legacy"`
`/me/inquiries` returns inquiry-kind signups UNIONed with rows from the legacy `inquiries` table (changelog 025, pre-dual-write noizu.com rows) matched by email, tagged `source:"legacy"` — so US-065 history is complete.

## D10 — Contact-prefs column home  *(prd-e Q2)*: on `signups` (Chunk B); Chunk E adds NO changelog
`signups.contact_prefs` (jsonb: frequency / channels / quiet-periods) + `signups.pause_until` (timestamptz nullable) are columns on the **signups** table, created in Chunk B's signups changelog. `lists.settings.contact_prefs` + `lists.settings.available_channels` hold the list-default baseline (effective pref = list-default overridden by the signup's `contact_prefs`). Chunk E (prd-e) adds **no separate `029-contact-preferences` changelog** — it only consumes/edits the storage Chunk B provides.

## D11 — Export + deletion fulfilment  *(prd-e Q3)*: sync JSON export now; deletion = stub queuer
`/me/export` returns a synchronous JSON dump now (Oban-async export is a later milestone). `/me/deletion-request` enqueues a stub (no immediate erasure) and returns an honest "queued" notice; the actual erasure job is later. Acceptable for M3.

## D12 — Route placement  *(prd-e Q4)*: `/app/me` is account-scoped; app shell must NOT force an org
`/app/me` is a sibling of `/app/[orgId]`, reachable without an org context. The app shell must not require an active org to show it (orgless users can still see their subscriptions/inquiries). Confirmed.

## D13 — Public list key  *(prd-b A)*: globally-unique `lists.public_slug` is canonical
`lists.public_slug` (globally unique) is the canonical key the public endpoint + widget use; the `services/:svc/lists/:list` path is a best-effort alias. (Avoids org-namespace collisions in public URLs.)

## D14 — List writes  *(prd-b B)*: admin/owner-only for M1 (seed unchanged)
Seed PBAC member policy is unchanged (only `*:view`/`*:list`). List create/update/archive are admin/owner-only via the existing wildcard admin/owner policies. The system api-key mgmt API bypasses PBAC (TF provisioning). If a "service editor" role needs list writes later, extend the seed then. Chunk D console is admin-gated anyway.

## D15 — Re-subscribe posture  *(prd-b C)*: no silent re-subscribe
A repeat POST to an explicitly `unsubscribed` row does NOT silently flip it back on. Double-opt-in lists send a fresh confirmation; single-opt-in lists stay `unsubscribed` until an explicit re-subscribe action. Stricter, compliance-friendly reading of US-043.

## D16 — Default inquiry list  *(prd-b E)*: TF-provisioned + env var
TF provisions a default foryou inquiry list; `FORYOU_DEFAULT_INQUIRY_LIST_ID` (set in deployment secrets) points the inquiries dual-write at it. The list MUST be provisioned before the dual-write is enabled.

## D17 — Signup rate limit  *(prd-b F)*: 5 req/60s per IP
`:rate_limited_signup` via Hammer = 5/60s/IP (distinct from the inquiries 3/60s pipeline).

## Authoritative-on-conflict note
**D10 (`signups.contact_prefs` + `pause_until`) is AUTHORITATIVE.** If `PRD-M1`'s signups DDL omits those columns, the Chunk B implementer MUST still add them (they're required by Chunk E). `DECISIONS.md` wins over any PRD omission.
