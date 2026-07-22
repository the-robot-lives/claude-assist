# PRD-M3: Admin Console (Chunk D)

**Version**: 1.0
**Status**: Draft (PRD gate — implementation-ready spec for Chunk D)
**Author**: npl-prd-editor
**Created**: 2026-07-22
**Updated**: 2026-07-22
**Roadmap milestone**: M3 (Chunks D + E) — original item 5
**Branch**: `develop` (shared multi-session checkout; do NOT git-worktree)

## Overview

The operator admin console at `/app/admin` — the surface where Keith (site owner /
platform operator) views signups to his services/lists across the portfolio, reviews
inquiries, and gauges activity. This is original request **item 5**: "admin page to
view signups to my channels/lists for different projects/services."

It is a **read-oriented** console (M3 scope): browse Services → Lists → Signups,
search/filter/sort/paginate, export CSV, drill into a single signup, and review
inquiries. Mutating admin actions (create/edit lists, manual subscribe/unsubscribe,
inquiry status workflows) are **out of scope** for Chunk D and reserved for a later
milestone — the Lists/Signups *domain* is created in Chunk B; Chunk D only *presents*
it. (US-071's guarded layout and the de-inlined `/app/admin/users`, `/app/app/orgs`
pages are landed in Chunk A; Chunk D extends that shell.)

### Goals

1. A guarded `/app/admin` shell (sidebar + sections) only admins can open — built on
   the fixed `RequireAdmin`/`:admin` schema (US-071, Chunk A).
2. A dashboard overview scoped to the operator's accessible Services.
3. Services list with aggregate counts; drill into a Service → its Lists with per-list
   signup counts and opt-in mode.
4. The core surface: a **Signups table per List** whose columns are derived from the
   List's declared attributes, with search, status filter, sort, pagination, and CSV
   export (export honors active filters).
5. A single-signup detail view (attributes, status, account linkage).
6. An Inquiries review view (search/filter/paginate + detail).
7. Observability hooks (US-099): signup volume / latency / rate-limit signals surfaced
   on the dashboard; logs correlate without leaking PII.
8. All presentation on the `sg-*` design system, extending it only with new primitives
   the console needs.

### Non-Goals

- Creating / editing / archiving Lists or Attributes (Chunk B domain + later write UI).
- Manual subscribe / unsubscribe / status change from the console (later milestone).
- The embeddable widget and public signup UX (Chunk C).
- Preference Center `/app/me` (Chunk E).
- noizu.com inquiry enhancement + listmonk migration (Chunks F, G).
- Campaign authoring / multi-channel delivery (post-M5).
- Anything the `/api/v1/management` (API-key) surface already does — that surface is for
  the Terraform provider / programmatic clients, **not** the browser console.

---

## Vocabulary note (important)

The README vocabulary is authoritative: **Service** = an existing `projects` row
(org → project/service); **List** = the user's word "channel" (new `lists` table);
**Signup** = a person on a list (new `signups` table). Backend naming is
`lists` / `signups` / `Foryou.Lists` / `Foryou.Signups` — **not** "channels". This PRD
uses Service/List/Signup consistently. Where a route says `:project_id`, that *is* the
Service.

---

## User Stories

| ID | Title | Priority | MoSCoW | Covered by |
|----|-------|----------|--------|------------|
| [US-071](../user-stories/US-071-guarded-admin-layout.md) | Access a guarded admin console | must | M | FR-001 |
| [US-072](../user-stories/US-072-admin-dashboard.md) | See an admin dashboard overview | must | M | FR-002 |
| [US-073](../user-stories/US-073-admin-services-with-counts.md) | List Services with signup counts | must | M | FR-003 |
| [US-074](../user-stories/US-074-admin-lists-with-counts.md) | List Lists per Service with counts | must | M | FR-004 |
| [US-075](../user-stories/US-075-view-signups-per-list.md) | View signups to my lists (item 5) | must | M | FR-005 |
| [US-076](../user-stories/US-076-search-filter-signups.md) | Search and filter signups | should | S | FR-006 |
| [US-077](../user-stories/US-077-sort-paginate-signups.md) | Sort and paginate the signups table | should | S | FR-007 |
| [US-078](../user-stories/US-078-export-signups-csv.md) | Export signups to CSV | must | M | FR-008 |
| [US-079](../user-stories/US-079-signup-detail.md) | View a single signup's detail | must | M | FR-009 |
| [US-080](../user-stories/US-080-admin-inquiries-view.md) | Review inquiries in the console | should | S | FR-010 |
| [US-099](../user-stories/US-099-observability.md) | Observe signups, rate-limits, abuse | should | S | FR-011 |

Screens: SCR-17 (layout+dashboard), SCR-18 (services+lists), SCR-19 (signups table +
detail), SCR-20 (inquiries) — see `../screens/`.

---

## Context & Dependencies

### Hard dependencies (must land before/with Chunk D)

1. **US-071 — `RequireAdmin` / `:admin` schema fix (Chunk A backend, in progress).**
   `ForyouWeb.Plugs.RequireAdmin` reads `Map.get(user, :admin, false)`, but
   `Foryou.Schema.Users.User` never declares `:admin` (column exists from changelog
   012) → the guard is always false today. Fix = add `field :admin, :boolean,
   default: false` (+ cast allowlist); no migration. **Until this lands, `/app/admin`
   rejects everyone and every AC below is blocked.** The frontend already checks
   `user.admin` (`admin/layout.tsx`) and `User.admin?` exists in `api.ts` — so the UI
   guard works the moment the backend returns the real flag.
2. **Chunk B — List/Signup domain + browser-authed read endpoints.** Chunk B builds the
   `lists` / `signups` tables (changelogs 026/027), `Foryou.Lists` / `Foryou.Signups`
   contexts, the public signup endpoint, and the API-key `/management` surface. **Chunk
   D additionally requires JWT-authed, PBAC-checked, browser-facing read endpoints**
   for lists & signups (see "Open Questions" Q1 — these may need to be added to Chunk
   B's scope or done at the top of Chunk D). The console does **not** use the
   `/management` API-key surface.
3. **`/app/admin` layout shell (Chunk A).** `src/app/app/admin/layout.tsx` already
   exists with sidebar + client-side `user.admin` guard and `Users`/`Orgs` nav links
   plus `Lists`/`Inquiries` placeholders. Chunk D replaces the placeholders with real
   routes and adds the dashboard.

### Confirmed backend facts (verified, from recon)

- Highest Liquibase changelog = **025**; list/signup tables are **026/027** (Chunk B).
- `inquiries` table (025) is **flat**: `name, email, message, source, page_url,
  metadata (map), status` — **no `project_id` / `user_id` today**. Enhanced
  company/project/budget/timeline fields land in Chunk F and are stored as **declared
  list attributes** on a noizu.com contact list, not on `inquiries`. Implication: the
  Chunk D Inquiries view reads the legacy `inquiries` table; project-association and
  enriched fields are partial/deferred (see Q3).
- Auth = Guardian JWT + SSO; org context via `useOrg()` (`src/context/org.tsx`),
  `currentOrg.id` available. Project (Service) routes are scoped under
  `/api/v1/organizations/:org_id/projects/...`.
- Frontend API client: `src/lib/api.ts` — single `request<T>(path, options)` helper
  with automatic token refresh + redirect-on-401, and an `api` object of methods. All
   new fetches are added as methods on `api`.
- CORS: endpoint-global reflect-origin plug already handles cross-origin (widget);
  admin console is same-origin and unaffected.

---

## Access model (authorization)

The console uses a **two-layer model** — keep this explicit, it is the most common
point of confusion:

| Layer | What it gates | Mechanism | Where |
|-------|---------------|-----------|-------|
| **Entry guard** | Can open `/app/admin` at all | `user.admin === true` via fixed `RequireAdmin` plug (`:admin` pipeline) + mirrored client-side redirect in `admin/layout.tsx` | Backend `/api/v1/admin/*` scope + client layout |
| **Data scoping** | Which Services/Lists/Signups are visible | **PBAC inherit-through-project**: `Authz.check_permission(uid, "project", project_id, "list:view")` — wildcard policies (changelog 020) already grant `*:view`/admin to project members/admins | Project-scoped endpoints under `/api/v1/organizations/:org_id/projects/...` |

**Rationale:** the stories require PBAC scoping ("a Service I lack access to is not
shown" — US-073; "metrics scoped to those Services only" — US-072), while the console
must stay operator-only (US-071). The `admin` flag is the coarse entry gate; PBAC is
the per-row authorization. Keith is org owner/admin and a member of his projects, so
PBAC grants him full visibility — exactly what he wants — and the model stays correct
for future multi-operator use.

**Recommendation:** drive Services / Lists / Signups entirely off the **project-scoped
PBAC endpoints** (single authorization model for the signup domain). The only global
`/admin` endpoints are the dashboard overview aggregate and the inquiries view
(inquiries are not project-linked yet). Alternative (a global `/admin/lists`,
`/admin/signups` tree that re-checks PBAC internally) is rejected — it duplicates the
project route tree and diverges from the existing convention.

---

## Routes

### Frontend (Next.js App Router, under `src/app/app/admin/`)

| Route | Screen | Purpose |
|-------|--------|---------|
| `/app/admin` (layout) | SCR-17 | Shell: sidebar + entry guard (existing from Chunk A; extend nav) |
| `/app/admin` (`page.tsx`) | SCR-17 | Dashboard overview (NEW) |
| `/app/admin/services` | SCR-18 | Services for the selected org with counts |
| `/app/admin/services/[projectId]` | SCR-18 | Lists in a Service with per-list counts + opt-in mode |
| `/app/admin/services/[projectId]/lists/[listId]` | SCR-19 | Signups table (search/filter/sort/page/export) |
| `/app/admin/services/[projectId]/lists/[listId]/signups/[signupId]` | SCR-19 | Signup detail |
| `/app/admin/inquiries` | SCR-20 | Inquiries review + detail panel |
| `/app/admin/users` | (existing) | Platform users (Chunk A) |
| `/app/admin/orgs` | (existing) | Platform orgs (Chunk A) |

The shell is **org-scoped**: it reads `currentOrg` from `useOrg()`. All project-scoped
fetches pass `currentOrg.id` as `:org_id`. An org selector (reuse the existing
org-switcher affordance) changes `currentOrg` and re-scopes the dashboard + Services
list. If the operator has zero orgs, show an empty state with a link to create one
(Chunk A create-org flow).

Update `admin/layout.tsx` `NAV_LINKS` to: Dashboard (`/app/admin`), Services
(`/app/admin/services`), Inquiries (`/app/admin/inquiries`), Users, Orgs. Remove the
`Lists`/`Inquiries` placeholder entries.

### Backend endpoint contract (consumed by Chunk D)

All are **JSON over HTTPS**, JWT-authed (`:authenticated` pipeline). Project-scoped
rows additionally enforce PBAC `list:view` (inherit-through-project). Pagination
follows the existing admin convention: `?page=&per_page=` (default `per_page=50`),
response echoes `{ total, page, per_page }`.

**Project-scoped (PBAC) — Services / Lists / Signups**

| Method | Path | Query | Returns | PBAC |
|--------|------|-------|---------|------|
| GET | `/api/v1/organizations/:org_id/projects` | `?with_counts=true` | `{ projects: [ { id, slug, name, status, list_count, signup_count } ] }` | `project:view` |
| GET | `/api/v1/organizations/:org_id/projects/:project_id/lists` | — | `{ lists: [ { id, slug, name, kind, status, opt_in_mode, signup_count, attribute_count } ] }` | `list:view` (inherit) |
| GET | `/api/v1/organizations/:org_id/projects/:project_id/lists/:list_id/signups` | `?q=&status=&sort=&order=&page=&per_page=` | `{ signups: [...], attributes: [...], total, page, per_page }` | `list:view` (inherit) |
| GET | `/api/v1/organizations/:org_id/projects/:project_id/lists/:list_id/signups/:id` | — | `{ signup: {...}, history: [...] }` | `list:view` (inherit) |
| GET | `/api/v1/organizations/:org_id/projects/:project_id/lists/:list_id/signups/export` | `?q=&status=&format=csv` | `text/csv` stream (one row per signup) | `list:view` (inherit) |

- `status` filter values: `pending_optin | subscribed | unsubscribed | bounced` (the
  signup status enum from Chunk B).
- `sort` values: `email | status | created_at` (default `created_at`, `order=desc`).
  Sorting on declared attribute columns is a **should-have**, not M3-blocking.
- `attributes` in the signups response is the ordered list of declared attributes
  `[{ key, label, type }]` so the table can render dynamic columns and the exporter can
  emit one column per attribute.
- `kind` / `opt_in_mode`: `kind` = `newsletter | waitlist | inquiry | contact | mixed`;
  `opt_in_mode` derives from kind + settings (`double` for newsletter/mixed, else
  `single`) — shown as a Badge (US-074).

**Global admin (RequireAdmin) — dashboard aggregate + inquiries**

| Method | Path | Query | Returns |
|--------|------|-------|---------|
| GET | `/api/v1/admin/overview` | `?org_id=` | `{ services, lists, signups, pending_optin, unsubscribed, bounced, recent_signups: [...], rate_limit_hits, signup_volume_24h }` |
| GET | `/api/v1/admin/inquiries` | `?q=&status=&source=&page=&per_page=` | `{ inquiries: [...], total, page, per_page }` |
| GET | `/api/v1/admin/inquiries/:id` | — | `{ inquiry: {...} }` |

- `overview` is scoped to the supplied `org_id` when present (the selected org), else
  to all orgs the operator can access. `rate_limit_hits` / `signup_volume_24h` feed the
  observability panel (US-099); see Q4 for source.
- Inquiries `status` filter values: `new | reviewed | closed | spam` (the existing
  `inquiries.status` set).

> **Contract ownership:** Chunk D implements the **frontend** that calls these. The
> project-scoped list/signup read endpoints and the two new `/admin` endpoints are the
> contract Chunk D expects Chunk B (or the top of Chunk D's backend lane) to provide.
> If Chunk B only ships the `/management` (API-key) surface, the JWT/PBAC read
> endpoints must be added — see Q1.

### Frontend `api.ts` additions

Add to the `api` object in `src/lib/api.ts` (mirror the existing
`adminListUsers`/`adminListOrganizations` style):

```ts
// Dashboard
adminOverview(orgId?: string);
// Services & lists
adminListServices(orgId: string);
adminListLists(orgId: string, projectId: string);
// Signups
adminListSignups(orgId: string, projectId: string, listId: string, opts: { q?, status?, sort?, order?, page?, per_page? });
adminShowSignup(orgId: string, projectId: string, listId: string, signupId: string);
adminExportSignupsCsv(orgId: string, projectId: string, listId: string, opts: { q?, status? }): Promise<Blob>;
// Inquiries
adminListInquiries(opts: { q?, status?, source?, page?, per_page? });
adminShowInquiry(id: string);
```

`adminExportSignupsCsv` must request `text/csv` and return a `Blob` (not parse as JSON);
the `request<T>` helper assumes JSON, so export uses a dedicated `fetch` with the same
auth header logic (token + refresh) and triggers a browser download via an object URL.

---

## Functional Requirements

### FR-001: Guarded admin shell (US-071)

**Status**: extends Chunk A shell.

**Interface**: `src/app/app/admin/layout.tsx` (existing). Entry guard:
- Client: if `!user.admin` → `router.replace("/app")`; if `!user` → `/login` (already
  implemented).
- Server-side data endpoints: `:admin` pipeline (fixed `RequireAdmin`) returns 403
  `{"error":"Admin access required"}` to non-admins; 401 when unauthenticated.

**Behavior**:
- Given an admin/owner, when navigating to `/app/admin`, then the layout renders with
  the sidebar (Dashboard, Services, Inquiries, Users, Orgs) and the selected section.
- Given a non-admin, when opening any `/app/admin/*` route, then the client redirects
  to `/app`; and a direct API call returns 403.
- Given the fixed schema, when the guard evaluates, then `user.admin` reflects the real
  role (not always false).

**Edge cases**:
- Token expires mid-session → `request<T>` auto-refresh handles it; if refresh fails,
  redirect to `/login` (existing).
- `user.admin` is `undefined` on a stale session → treat as non-admin (fail closed).

**Test coverage**: ~4 tests (admin allowed, non-admin redirected, 403 on direct API,
undefined-admin fails closed).

---

### FR-002: Dashboard overview (US-072, US-099)

**Interface**: `GET /api/v1/admin/overview?org_id=` → `api.adminOverview(orgId)`.

**Behavior**:
- Given the operator opens `/app/admin`, when the dashboard loads, then StatTiles show
  total **Services**, **Lists**, **Signups** (plus `pending_optin`, `unsubscribed`,
  `bounced`), and a **recent activity** list (latest N signups across accessible
  services with email/status/service/list/ timestamp).
- Given access to several Services, when rendering, then all counts are **scoped to the
  selected org** (org switcher re-fetches).
- Given no activity yet, when loading, then a clear zero/empty state renders (not a
  broken/blank tile).
- (US-099) A MetricsPanel shows signup volume (last 24h) and rate-limit hits; values
  come from the overview payload.

**Edge cases**:
- `overview` 403 → session lost admin flag; surface "Admin access required" + redirect.
- Slow aggregate → show skeleton tiles (see FR-012), not a blank page.

**Test coverage**: ~5 tests (scoped counts, empty state, org switch re-fetch,
observability payload rendering, 403 handling).

---

### FR-003: Services list with counts (US-073)

**Interface**: `GET /api/v1/organizations/:org_id/projects?with_counts=true` →
`api.adminListServices(orgId)`.

**Behavior**:
- Given the operator opens `/app/admin/services`, when it loads, then each Service row
  shows name, slug, **list_count**, and **signup_count**.
- Given a Service, when selected, then drill into `/app/admin/services/[projectId]`
  (its Lists — FR-004).
- Given a Service the operator lacks access to (PBAC), when the list renders, then it
  is **not present** (the endpoint excludes it; not hidden client-side).

**Edge cases**:
- Zero Services → empty state with link to create an org/project (out of console
  scope to create).
- `with_counts` adds a join/aggregate; ensure no N+1 (single query with counts).

**Test coverage**: ~4 tests (counts present, drill-in navigates, PBAC-excluded service
absent, empty state).

---

### FR-004: Lists per Service with counts (US-074)

**Interface**: `GET /api/v1/organizations/:org_id/projects/:project_id/lists` →
`api.adminListLists(orgId, projectId)`.

**Behavior**:
- Given an open Service, when its lists load, then each List row shows name, slug,
  **kind**, **opt_in_mode** (Badge), **signup_count**, and **attribute_count**.
- Given a List, when opened, then navigate to its Signups table (FR-005).
- Given a List with zero signups, when rendered, then it shows `0` (not a missing row).

**Edge cases**:
- Service with zero Lists → empty state ("No lists yet — create one" links to future
  write UI; M3 just shows the empty state).
- Archived lists: include with a muted/archived badge by default; a toggle can hide
  them (should-have).

**Test coverage**: ~4 tests (counts + opt-in badge present, drill-in, zero-count row,
empty state).

---

### FR-005: Signups table per List (US-075) — core surface

**Interface**:
`GET /api/v1/organizations/:org_id/projects/:project_id/lists/:list_id/signups` →
`api.adminListSignups(orgId, projectId, listId, opts)`.

**Behavior**:
- Given an open List, when the table loads, then each row shows **email, status
  (Badge), created_at**, plus **one column per declared attribute** (rendered by type —
  see FR-012) — columns derived from the `attributes` array in the response.
- Given the List declares custom attributes, when the table renders, then columns
  reflect those declared attributes (dynamic, not hardcoded).
- Given access to multiple Services/Lists, when switching context, then the table
  re-scopes to the selected List (route-driven; no stale rows).

**Edge cases**:
- Zero signups → empty state ("No signups yet").
- A declared attribute value missing on a row → render muted placeholder `—`.
- Very long attribute values → truncate with title tooltip.

**Test coverage**: ~6 tests (dynamic columns, status badge, empty state, missing-value
placeholder, context switch rescopes, archived list badge).

---

### FR-006: Search + filter signups (US-076)

**Interface**: signups endpoint `?q=&status=`; UI `SearchFilterBar`.

**Behavior**:
- Given the table, when searching by `q` (email substring OR any declared attribute
  value substring), then matching signups show (case-insensitive).
- Given a status filter (`pending_optin | subscribed | unsubscribed | bounced`), when
  applied, then only that status shows.
- Given active filters, when exporting (FR-008), then the export respects them.

**Edge cases**:
- `q` shorter than minimum (e.g. 1 char) — debounce 250ms; do not fire on every
  keystroke.
- No matches → "No signups match your filters" + clear-filters action.
- Search on attribute values indexes the `attribs` jsonb (backend concern — flag if
  jsonb containment is too slow on large lists; see Q5).

**Test coverage**: ~5 tests (email search, attribute-value search, status filter,
export honors filters, clear-filters).

---

### FR-007: Sort + paginate (US-077)

**Interface**: signups endpoint `?sort=&order=&page=&per_page=`.

**Behavior**:
- Given a large list, when the table loads, then it paginates (`per_page=50` default)
  and Prev/Next move between pages (reuse `sg-pagination` pattern from `admin/users`).
- Given a sortable column (`email | status | created_at`), when sorted, then rows
  reorder and the current page/filter context is preserved in the querystring.
- Given a very large list, when paging/sorting, then responses stay performant
  (keyset/limit-offset + index on `(list_id, created_at)` / `(list_id, lower(email))`).

**Edge cases**:
- Sort + filter + page combined → all params compose in the URL (deep-linkable /
  shareable; back-button works).
- Next disabled when `signups.length < per_page` (matches existing admin pattern).

**Test coverage**: ~4 tests (pagination nav, sort reorder, URL composition preserves
filter+page, Next-disabled at last page).

---

### FR-008: CSV export (US-078) — must-have

**Interface**:
`GET .../lists/:list_id/signups/export?q=&status=&format=csv` →
`api.adminExportSignupsCsv(...)` → `Blob` → browser download.

**Behavior**:
- Given a List's signups (optionally filtered by the active search/status), when
  exporting, then the browser downloads a CSV with **one row per signup** and columns:
  `email, status, created_at` **+ one column per declared attribute** (header = attribute
  label or key).
- Given the List has custom attributes, when exporting, then each attribute is its own
  column (mirrors the table).
- Given a large list, when exporting, then the export **streams** (backend sends
  chunked `text/csv`; client streams to download) and completes without timeout.

**Edge cases**:
- RFC-4180 compliance: quote fields containing comma/quote/newline; UTF-8 BOM optional
  for Excel.
- Honors active `q` / `status` filters (same params as the list endpoint).
- Export while filters active is reflected in the downloaded filename, e.g.
  `signups-<list>-status=subscribed-<date>.csv`.
- No signups under the filter → CSV with header row only (not an empty file).
- Same data path as the `/management GET .../signups` backfill export (US-078 note):
  align column order/format so the two are interchangeable.

**Test coverage**: ~5 tests (header + dynamic columns, filter respected, large-list
stream completes, quoting, empty-result header-only).

---

### FR-009: Signup detail (US-079)

**Interface**:
`GET .../lists/:list_id/signups/:id` → `api.adminShowSignup(...)`.

**Behavior**:
- Given a signup row, when opened, then a detail view shows full attribute values,
  status (with history if available), contact preferences (if any), and created_at.
- Given the signup is linked to a user account (`user_id` present), when viewing, then
  the linkage is shown (account id/email) — read-only.
- Given the operator lacks permission (PBAC), when opening, then access is denied
  (403 → "Access denied").

**Edge cases**:
- Signup with `user_id IS NULL` (not yet reconciled) → show "Not linked to an account".
- No status history yet (history table deferred) → show current status only.

**Test coverage**: ~4 tests (full attributes render, account linkage shown,
unlinked-state message, 403 denied).

---

### FR-010: Inquiries review (US-080)

**Interface**: `GET /api/v1/admin/inquiries?q=&status=&source=&page=&per_page=` and
`GET /api/v1/admin/inquiries/:id`.

**Behavior**:
- Given inquiries exist, when opening `/app/admin/inquiries`, then each row shows
  submitter (name/email), source, status, and date.
- Given an inquiry, when opened, then the detail shows full `message` + `metadata`
  (company/project/budget/timeline when present — Chunk F writes these into
  `metadata`/attributes; until then, `metadata` map is rendered key-by-key).
- Given many inquiries, when browsing, then search/filter (`status`, `source`) and
  paginate are available (reuse SearchFilterBar + `sg-pagination`).

**Edge cases**:
- Inquiries are not yet project-linked (flat table) → no Service column in M3; show
  `source` as the site proxy. (See Q3.)
- `metadata` empty → hide the metadata section.
- Spam status → visually de-emphasized (muted row).

**Test coverage**: ~4 tests (list renders, detail shows metadata, status/source
filter, pagination).

---

### FR-011: Observability hooks (US-099)

**Interface**: dashboard MetricsPanel fed by `adminOverview()`; relies on backend
metrics (US-100 rate-limiting + existing telemetry).

**Behavior**:
- Given the public endpoint is live, when signups occur, then the dashboard surfaces
  signup volume (last 24h) and success/failure counts.
- Given rate-limiting active, when limits trip, then `rate_limit_hits` is visible on
  the dashboard (and an abuse spike is obvious).
- Given an incident, when investigating, then backend logs correlate a request to its
  outcome **without leaking PII** (emails/token never logged).

**Edge cases**:
- Metrics source not yet wired (US-100/telemetry incomplete) → degrade gracefully:
  hide the MetricsPanel rather than show `NaN`/errors (see Q4).

**Test coverage**: ~3 tests (panel renders from payload, graceful degradation when
metrics absent, no PII in logged request correlation).

---

### FR-012: Design-system presentation (`sg-*`)

**Status**: extends the existing design system; no bespoke per-page CSS.

**Behavior**: all console UI uses `sg-*` classes. **Reuse existing**: `sg-admin-shell`,
`sg-admin-sidebar`, `sg-admin-nav`, `sg-admin-nav-link` (+`--active`), `sg-admin-main`,
`sg-section-heading`, `sg-section-header`, `sg-table`, `sg-pagination` (+`__status`),
`sg-btn` (+`--outline`, `--sm`), `sg-admin-loading`, `sg-error`, `sg-page-intro`.

**New primitives to add** to the design system (generated via the existing
`generate-css` step; keep names consistent with `sg-*` convention):
- `sg-stat-tile` / `sg-stat-grid` — dashboard count tiles (label + value).
- `sg-badge` (+ `--success | --warning | --danger | --muted`) — signup status + opt-in
  mode + inquiry status.
- `sg-data-table` (extend `sg-table`) — sortable header cells (`sg-data-table__th--sortable`,
  `--asc`, `--desc`).
- `sg-toolbar` + `sg-search` — search input + filter selects above the table.
- `sg-empty-state` — zero/empty messaging (icon + text + optional CTA).
- `sg-skeleton` — loading placeholders for tiles/rows.
- `sg-back-link` — "← Back to Lists" navigation.
- `sg-detail-panel` — signup/inquiry detail layout.

**Edge cases**: dark-mode + light-mode both styled (design system is theme-aware);
responsive — tables scroll horizontally on narrow viewports (`overflow-x: auto`
wrapper, body never scrolls horizontally).

**Test coverage**: ~2 tests (sort-header aria/state toggles, empty-state renders).

---

## Error handling

| Condition | Backend | Frontend |
|-----------|---------|----------|
| Non-admin hits `/admin` endpoint | 403 `{"error":"Admin access required"}` | redirect `/app`; toast "Admin access required" |
| No PBAC `list:view` on project/list | 403 | "Access denied" panel; offer back-link |
| List/signup not found | 404 | "Not found" empty state + back-link |
| Token expired | 401 → auto-refresh; retry | transparent; if refresh fails → `/login` |
| Export timeout/stream error | 5xx | toast "Export failed — try again"; button re-enables |
| Overview aggregate slow/fails | 5xx | skeleton tiles + retry; never blank |
| Metrics unavailable (US-99) | omit fields | hide MetricsPanel gracefully |

All user-facing messages are plain text (no PII, no stack traces). Errors from `request<T>`
already surface `body.error` — reuse, don't rewrap.

---

## Acceptance Tests

Tied to story ACs. Full cases live in `acceptance-tests/` at implementation time; key
coverage:

- **AT-001 (US-071)**: admin opens `/app/admin` → shell renders; non-admin → redirected;
  direct API → 403; `user.admin` reflects real role.
- **AT-002 (US-072)**: dashboard shows scoped counts; org switch re-scopes; zero-state
  renders; MetricsPanel shows volume/rate-limit (or hides gracefully).
- **AT-003 (US-073)**: Services listed with list_count + signup_count; drill-in works;
  PBAC-excluded Service absent; empty state.
- **AT-004 (US-074)**: Lists shown with signup_count + opt-in badge; zero-count row
  shows `0`; drill-in to signups.
- **AT-005 (US-075)**: signups table renders dynamic attribute columns; status badge;
  context switch rescopes; empty/missing-value states.
- **AT-006 (US-076)**: email + attribute search; status filter; export honors filters;
  clear-filters.
- **AT-007 (US-077)**: pagination nav; sort reorder; URL composes filter+page+sort;
  Next disabled at last page.
- **AT-008 (US-078)**: CSV has header + dynamic columns; filters respected; large list
  streams; quoting correct; empty filter → header-only.
- **AT-009 (US-079)**: detail shows all attributes + linkage; unlinked message; 403
  denied.
- **AT-010 (US-080)**: inquiries list + detail (metadata); status/source filter;
  pagination.
- **AT-011 (US-099)**: observability panel renders from payload; graceful degradation;
  no PII in logs.
- **AT-012 (design-system)**: only `sg-*` classes used; new primitives themed
  light/dark; tables scroll on narrow viewports.

---

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Signups table first paint | Time to rows | < 300ms at p50 for per_page=50 (indexed) |
| NFR-2 | CSV export of 10k signups | Wall clock | completes without timeout (streamed) |
| NFR-3 | No PII in logs | Review | 0 emails/tokens in structured logs |
| NFR-4 | tsc / build | `npm run build` | 0 errors |
| NFR-5 | Accessibility | WCAG | sortable headers + filters keyboard-reachable; status conveyed via text not color alone |
| NFR-6 | Test coverage of new frontend | Lines | >= 80% |

---

## Success Criteria

1. Original item 5 fulfilled: operator can view signups to any list across any service,
   with search/filter/sort/paginate + CSV export (US-075/076/077/078).
2. Dashboard, Services, Lists, Signup-detail, Inquiries all functional and PBAC-scoped.
3. `/app/admin` correctly gated by the fixed `RequireAdmin` (US-071 landed).
4. `npm run build` passes with 0 tsc errors; frontend test coverage >= 80%.
5. Smoke (claude-in-chrome): admin sees a public signup (submitted via Chunk B/C
  endpoint) appear in the table; CSV export downloads; non-admin is redirected.
6. Presentation entirely on `sg-*` (light + dark).

---

## Out of Scope (Chunk D)

- Create/edit/archive Lists or Attributes (write UI — later milestone).
- Manual subscribe/unsubscribe/status edits; inquiry status workflows.
- Preference Center `/app/me` (Chunk E).
- noizu.com inquiry enhancement + listmonk migration (Chunks F, G).
- Campaign authoring; multi-channel delivery (post-M5).
- Sorting/filtering on arbitrary attribute columns beyond `email/status/created_at`
  (should-have; deferred if jsonb indexing is costly).
- Project-linking inquiries (deferred — see Q3).

---

## Dependencies

- **US-071 / Chunk A backend**: `RequireAdmin` `:admin` schema fix + guarded layout.
- **Chunk B**: `lists`/`signups` tables (026/027), `Foryou.Lists`/`Foryou.Signups`
  contexts, declared-attribute model, PBAC `list:view` inherit-through-project, **and
  the JWT-authed project-scoped read endpoints** the console consumes (see Q1).
- **US-100 / telemetry**: rate-limit + signup-volume metrics feeding the observability
  panel (US-099); degrade gracefully if absent.
- Design-system `generate-css` pipeline (to add the new `sg-*` primitives).

---

## Open Questions (ambiguities to resolve before/during implementation)

- **Q1 — Browser-authed list/signup endpoints.** Chunk B's verified design emphasizes
  the public endpoint + `/management` (API-key) surface + `/me` self-service. The
  **JWT-authed, PBAC-checked, project-scoped read endpoints** the console needs
  (`GET .../projects/:id/lists`, `.../lists/:id/signups`, detail, export) are not
  explicitly in that scope. *Decision needed:* add them to Chunk B, or implement at the
  start of Chunk D's backend lane. This PRD assumes they exist with the contract above.
  **(Highest-risk item.)**
- **Q2 — Export format.** CSV is specified (RFC-4180, one column per declared attribute,
  honors filters, streamed). Confirm: (a) UTF-8 BOM for Excel? (b) include
  `unsubscribed`/`bounced` rows by default or only `subscribed`+`pending_optin`? This
  PRD defaults to **all statuses** with a `status` column so the operator can filter
  downstream; the management backfill export should match.
- **Q3 — Inquiries project association.** The `inquiries` table has no `project_id`
  today, so the Chunk D Inquiries view cannot group by Service. Options: (a) leave it
  flat (show `source` only) for M3; (b) add a nullable `project_id` migration in Chunk
  D. This PRD defaults to **(a) flat for M3**; project-linking arrives with Chunk F.
- **Q4 — Observability source.** `rate_limit_hits` / `signup_volume_24h` require a
  metrics backend (Telemetry → Oneuptime / SigNoz?). If US-100/telemetry is not live in
  M3, the MetricsPanel hides gracefully. Confirm whether to wire a real metrics query
  now or stub from request logs.
- **Q5 — Attribute-value search performance.** Searching `q` against jsonb attribute
  values may need a GIN index on `signups.attribs`. Flag for Chunk B; if costly, M3
  restricts `q` to email-only and attribute-value search becomes a later enhancement.
- **Q6 — Pagination strategy.** Offset/limit is fine for `<~50k` rows per list; very
  large lists (post-listmonk-backfill) may need keyset pagination. Default offset/limit
  for M3; revisit if exports/paging regress on backfilled lists.
