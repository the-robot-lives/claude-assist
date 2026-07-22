# PRD-M3: Preference Center (Chunk E)

**Version**: 1.0
**Status**: Draft
**Author**: npl-prd-editor
**Milestone**: M3 — Admin Console + Preference Center + Contact Preferences
**Chunk**: E (item 6 — "user page to view lists/inquiries")
**Plan ref**: `~/.claude/plans/resilient-beaming-wozniak.md` (Chunk E)
**Roadmap ref**: `project-management/roadmap/README.md` (M3 / Preference Center)
**Created**: 2026-07-22

---

## Overview

The **Preference Center** is the authenticated, account-scoped surface at
`/app/me` where a person with one foryou account manages every subscription and
inquiry across the **entire DeRobot portfolio** — `foryou.therobotlives.com`,
`codefre.sh`, and every other site that funnels signups into foryou. It is the
product realization of the README's *"Unified preference center"*: one
authoritative, cross-site view of what a person has subscribed to and how they
want to be reached.

Chunk E delivers three things atop the Chunk B list/signup domain:

1. **My subscriptions** — every signup across all Services, grouped by site,
   with unsubscribe / re-subscribe / resume and a per-subscription preference
   editor.
2. **My inquiries** — inquiry/contact-kind signups the person has submitted,
   with status and history.
3. **Contact-preference controls** — frequency, quiet periods, channel toggles,
   and pause — **stored**, not sent (multi-channel *sending* is explicitly
   post-M5 / won't-have).

It is account-scoped, not org-scoped: the page renders for the authenticated
user regardless of which org/service is selected in the app shell.

### Goals

1. One login → one cross-site view of all subscriptions + inquiries (US-061,
   US-064).
2. Self-service unsubscribe (and re-subscribe/resume) without an email link
   (US-062, US-066).
3. Per-subscription contact-preference editing with list-default inheritance
   and override (US-051–US-053, US-055, US-063).
4. Privacy self-service: export my data, request deletion (US-067, US-068).
5. Fully accessible, low-bandwidth-friendly (US-057, US-069).

### Non-Goals

- **Multi-channel delivery** (SMS / push / webhook / physical mail *senders*) —
  US-058/059/060 are won't-have, post-M5. Chunk E only **stores** channel
  preferences; it sends nothing on those channels.
- **Campaign authoring / scheduled digest delivery** that *honors* frequency —
  that ships with the senders later. Frequency/quiet-period values are stored
  now and enforced when delivery lands.
- **Admin console** (per-service/list signup tables, export CSV) — that is
  Chunk D (item 5).
- **List-default editor UI** for Service editors (US-054's editor surface in
  SCR-08) — owned by list management. Chunk E *consumes* the list defaults as
  the inheritance baseline and defines the shared storage contract (see
  Dependencies).
- **Public token-based unsubscribe page** (US-042, SCR-13) — Chunk B. Chunk E's
  authed unsubscribe must produce the **same** resulting state.

---

## User Stories

| ID | Title | Priority | Epic |
|----|-------|----------|------|
| [US-061](../user-stories/US-061-unified-preference-center.md) | View my subscriptions and inquiries in one place | **must** | Preference Center |
| [US-064](../user-stories/US-064-cross-site-grouping.md) | Group my subscriptions by site | **must** | Preference Center |
| [US-062](../user-stories/US-062-unsubscribe-in-center.md) | Unsubscribe from a list in the preference center | **must** | Preference Center |
| [US-051](../user-stories/US-051-set-contact-frequency.md) | Set my contact frequency | **must** | Contact Preferences |
| [US-052](../user-stories/US-052-choose-contact-channels.md) | Choose my contact channels | **must** | Contact Preferences |
| [US-063](../user-stories/US-063-edit-preferences-per-subscription.md) | Edit contact preferences per subscription | should | Preference Center |
| [US-053](../user-stories/US-053-set-quiet-periods.md) | Set quiet periods for contact | should | Contact Preferences |
| [US-055](../user-stories/US-055-override-list-defaults.md) | Override list defaults for my subscription | should | Contact Preferences |
| [US-065](../user-stories/US-065-view-my-inquiries.md) | View my submitted inquiries | should | Preference Center |
| [US-067](../user-stories/US-067-export-my-data.md) | Export my data | should | Preference Center |
| [US-069](../user-stories/US-069-accessible-preference-center.md) | Use an accessible preference-center dashboard | should | Preference Center |
| [US-070](../user-stories/US-070-preference-center-empty-state.md) | Helpful empty state with no subscriptions | should | Preference Center |
| [US-057](../user-stories/US-057-accessible-preference-controls.md) | Use accessible preference controls | should | Contact Preferences |
| [US-054](../user-stories/US-054-list-preference-defaults.md) | Set per-list preference defaults *(contract only — editor UI is list mgmt)* | should | Contact Preferences |
| [US-066](../user-stories/US-066-resubscribe-and-resume.md) | Re-subscribe or resume a paused list | could | Preference Center |
| [US-056](../user-stories/US-056-pause-contact.md) | Pause all contact temporarily | could | Contact Preferences |
| [US-068](../user-stories/US-068-request-account-deletion.md) | Request account and data deletion | could | Preference Center |

MoSCoW recap for this chunk: **must** = US-061, US-064, US-062, US-051, US-052
(the chunk gate); **should** = US-063, US-053, US-055, US-065, US-067, US-069,
US-070, US-057, US-054 (contract); **could** = US-066, US-056, US-068
(deferrable without blocking the gate).

---

## Scope

### In scope

- Authenticated route `/app/me` and its data-loading against the `/me`
  endpoints.
- Cross-site subscription grouping, per-row actions, empty state.
- Authed unsubscribe + (could-have) re-subscribe / resume.
- Per-subscription contact-preference editor modal (frequency, channels, quiet
  periods, pause, reset-to-default) and its backend mutation endpoint.
- My inquiries section.
- Export-my-data and request-deletion endpoints + UI.
- Accessibility + low-bandwidth hardening.

### Out of scope (explicit)

- Any non-email channel **sending** (US-058/059/060 — post-M5 won't-have).
- Campaign/digest scheduling that honors frequency/quiet-period at send time.
- Admin console + per-list signup table (Chunk D).
- The Service-editor list-default editor UI (US-054 editor surface, SCR-08).
- Public token unsubscribe page (Chunk B, US-042).
- listmonk migration / cutover (Chunks G/H).

---

## Backend dependencies & new endpoints

### Provided by Chunk B (hard dependencies — must land first)

These resolve the authenticated user **by `user_id` OR `email`** so that
anonymous signups attach to the account via reconcile-on-login (US-050).

| Endpoint | Method | Returns | Notes |
|---|---|---|---|
| `/api/v1/me/signups` | GET | `{ signups: SignupView[] }` | All signups for the user across all Services. |
| `/api/v1/me/inquiries` | GET | `{ inquiries: InquiryView[] }` | Signups where `list.kind IN ('inquiry','contact')`. |
| `/api/v1/me/signups/:id` | DELETE | `{ id, status: 'unsubscribed' }` | Authed unsubscribe; same end-state as token unsubscribe (US-042). |

`SignupView` shape (Chunk B must return this, joined through list → service):

```json
{
  "id": "uuid",
  "status": "subscribed|pending_optin|unsubscribed|bounced",
  "email": "user@example.com",
  "subscribed_at": "ISO8601",
  "contact_prefs": { /* see Data Model; effective prefs */ },
  "list": { "id": "uuid", "name": "Weekly Digest", "slug": "weekly-digest",
            "kind": "newsletter", "settings": { "contact_prefs": { /* defaults */ },
            "available_channels": ["email"] } },
  "service": { "id": "uuid", "name": "codefre.sh", "slug": "codefre-sh",
               "branding": { "name": "codefre.sh" } },
  "can_resubscribe": true
}
```

If Chunk B does not already return the joined `list`, `service`, and
`contact_prefs` fields, **Chunk E extends the view** to include them (read-only
join; no new table). Coordinate at the `Foryou.Signups` context boundary.

### Introduced by Chunk E (new)

| Endpoint | Method | Purpose | FR |
|---|---|---|---|
| `/api/v1/me/signups/:id` | PATCH | Update contact preferences (frequency, channels, quiet_periods, pause_until) or reset-to-default. | FR-005, FR-006 |
| `/api/v1/me/signups/:id/resubscribe` | POST | Re-activate an unsubscribed signup per the list's opt-in mode (re-confirm email if double opt-in). | FR-007 |
| `/api/v1/me/signups/:id/resume` | POST | Clear `pause_until`; resume at prior prefs. | FR-007 |
| `/api/v1/me/export` | GET | Stream/return a machine-readable export of the user's subscriptions, prefs, and inquiries. | FR-009 |
| `/api/v1/me/deletion-request` | POST | Create a deletion request (confirm flow; not instant). | FR-010 |

All `/me/*` endpoints require an authenticated Guardian session (existing
`:authenticate` pipeline). They are **account-scoped**: authorization is "this
resource belongs to `current_user.id` (or matches `current_user.email`)" — no
PBAC/org membership check. A request for another user's signup id returns
**404** (not 403) to avoid existence leak, consistent with the public endpoint's
no-leak posture.

---

## Data Model

Contact preferences are stored on the signup (subscriber override) with
inheritance from the list default. Chunk E owns a focused Liquibase changelog
so it does not collide with Chunk B's 026-lists / 027-signups.

**Changelog `029-contact-preferences`** (new — verify Chunk B's 027 does not
already add these columns; if it does, drop them from 029):

- `signups.contact_prefs` — `jsonb`, nullable. Holds the subscriber's explicit
  **override** values only. `NULL` ⇒ inherit list default.
- `signups.pause_until` — `timestamptz`, nullable. Real column (queryable by the
  future sender for pause enforcement).
- `lists.settings.contact_prefs` — jsonb path (settings already jsonb from 026).
  Holds list **defaults** + `available_channels`.

**`contact_prefs` JSON shape** (identical for override and list default so
merge is trivial):

```json
{
  "frequency": "immediate|daily|weekly|monthly",
  "channels": { "email": true, "sms": false, "push": false, "webhook": false, "physical_mail": false },
  "quiet_periods": [
    { "start": "22:00", "end": "07:00", "timezone": "America/Los_Angeles", "days": ["mon","tue","wed","thu","fri"] }
  ]
}
```

**Effective-preference resolution** (computed server-side in the response, and
on save):

```
effective.frequency   = override.frequency   ?? list_default.frequency   ?? "immediate"
effective.channels[k] = override.channels[k] ?? list_default.channels[k] ?? (k == "email")
effective.quiet_periods = override.quiet_periods ?? list_default.quiet_periods ?? []
available_channels = list_default.available_channels ?? ["email"]
```

- A channel not in `available_channels` is **not selectable** in the editor and
  is forced `false` on save (US-052, US-063).
- Reset-to-default sets `contact_prefs = NULL` (US-055); the effective prefs
  revert to the list default on next read.
- Saving any explicit value flips that field from "inherited" to "overridden";
  later list-default changes do **not** silently reset explicit overrides
  (US-055).

---

## Functional Requirements

### FR-001: Authenticated preference-center route & data loading

**Status**: Draft — **must**

**Description**: An authenticated `/app/me` route that loads the user's
cross-site subscriptions and inquiries; redirects unauthenticated visitors to
login.

**Interface (frontend)**:
- Route: `app/frontend/src/app/app/me/page.tsx` (sibling of `[orgId]` —
  **account-scoped, not org-scoped**).
- Sub-routes: `app/me/` (dashboard), `app/me/inquiries` (SCR-16), optional
  `app/me/privacy` (export/deletion).
- Guard: existing `AuthContext`; if `!user` → `<Redirect href="/login" />`.

**Interface (data)**:
```ts
const { signups } = await api.getMySignups();      // GET /api/v1/me/signups
const { inquiries } = await api.getMyInquiries();  // GET /api/v1/me/inquiries
```
Add to `src/lib/api.ts` (follows the existing `request<T>` bearer-token +
401-refresh pattern at `api.ts:73`).

**Behavior**:
- Given an authenticated user at `/app/me`, when the page loads, then it
  fetches `/me/signups` and `/me/inquiries` in parallel and renders both.
- Given no `access_token`, when the route is hit, then the user is redirected
  to `/login?next=/app/me`.
- Given signups that arrive after reconcile-on-login, when the user returns,
  then newly attached signups appear without a hard refresh (US-070 AC3).

**Edge cases**:
- 401 mid-session → existing refresh+retry; refresh fail → redirect `/login`.
- Network failure → InlineAlert + retry (not a blank page).
- Partial: subscriptions loaded but inquiries 5xx → render subscriptions, show
  InlineAlert on the inquiries section only.

**Related stories**: US-061, US-069. **Expected tests**: 6–8.

---

### FR-002: Cross-site subscription grouping

**Status**: Draft — **must**

**Description**: Group the returned signups by Service and render each group
with the site's name/branding.

**Interface**: Client-side group `signups` by `service.id` (stable order: by
service name, then list name). Render one `SubscriptionGroup` per service using
component **CMP-14 SubscriptionList**.

**Behavior**:
- Given subscriptions across multiple services, when rendered, then they are
  grouped by service, each group headed by the service name/branding.
- Given a single service, when rendered, then grouping still displays cleanly
  with one group (no orphan "ungrouped" bucket).
- Given a signup whose `service` is null (defensive), when grouped, then it
  falls under an "Other" group rather than crashing.

**Edge cases**: two services with identical display names → disambiguate by
slug/subtitle. Service with no branding → use `service.name`.

**Related stories**: US-064, US-061. **Expected tests**: 4–6.

---

### FR-003: Subscription row display & actions

**Status**: Draft — **must**

**Description**: Each subscription renders its service, list, status, subscribed
date, and contextual quick actions.

**Interface**: `SubscriptionRow` — columns/areas:
- Service name + list name
- Status badge via **CMP-10 StatusBadge** (`subscribed` / `pending_optin` /
  `unsubscribed` / `bounced`, plus a `paused` overlay when `pause_until` is
  future)
- Subscribed date
- Actions: **Manage** (opens FR-005 editor), **Unsubscribe** (FR-004); when
  `status == unsubscribed` → **Re-subscribe** (FR-007); when paused → **Resume**
  (FR-007).

**Behavior**:
- Given an active subscription, when rendered, then service, list, status, and
  date are all present and quick actions are visible.
- Given `can_resubscribe == false` (list archived / not re-enterable), when
  unsubscribed, then Re-subscribe is hidden or disabled with a tooltip.

**Edge cases**: `pending_optin` shows a "confirm your email" hint link, not an
unsubscribe action (nothing to unsubscribe yet — a cancel-pending action is
optional).

**Related stories**: US-061. **Expected tests**: 4–5.

---

### FR-004: Unsubscribe from a subscription

**Status**: Draft — **must**

**Description**: Signed-in user unsubscribes from a list directly in the
dashboard; result is consistent with token-based unsubscribe.

**Interface**: `api.unsubscribeMySignup(id)` → `DELETE /api/v1/me/signups/:id`.

**Behavior**:
- Given an active subscription, when the user chooses Unsubscribe (with a
  ConfirmDialog — **CMP-18**), then `DELETE` fires and the row's status becomes
  `unsubscribed`.
- Given a successful unsubscribe, when the UI updates, then the change is
  announced via live region (FR-012) and matches the state a token-unsubscribe
  link would produce (US-042).
- Given an already-unsubscribed row, when Unsubscribe is invoked, then the call
  is idempotent (no error surfaced).

**Edge cases**: 404 on the row (deleted elsewhere) → remove row + announce;
network error → InlineAlert, row unchanged (no false success).

**Related stories**: US-062. **Expected tests**: 4–6.

---

### FR-005: Per-subscription contact-preference editor (subscriber side)

**Status**: Draft — **should**

**Description**: A modal editor (SCR-15) letting the subscriber set frequency,
channels, quiet periods, and pause; override then reset to list default. Uses
**CMP-13 PreferenceControls**.

**Interface**:
- Triggered by **Manage** on a row (FR-003).
- Controls:
  - **FrequencySelect** — immediate/daily/weekly/monthly.
  - **ChannelToggles** — `email` active; `sms`/`push`/`webhook`/`physical_mail`
    selectable but visually flagged "stored — delivery coming soon"
    (**InlineAlert**, CMP-04). Only channels in `available_channels` are
    selectable; others hidden or locked.
  - **QuietPeriodEditor** — start/end, timezone (default to a sensible zone,
    shown to the user), optional days.
  - **PauseControl** — snooze until a chosen date (sets `pause_until`).
  - **ResetToDefaultButton** — clears override (`contact_prefs = NULL`).
- Save → `PATCH /api/v1/me/signups/:id` (FR-006).

**Behavior**:
- Given a subscription, when the editor opens, then it shows the **effective**
  prefs (override-or-default), with inherited-vs-overridden visually
  distinguishable.
- Given a list restricts channels, when editing, then only offered channels are
  selectable (US-052 AC3, US-063 AC3).
- Given the user saves changes, when the PATCH returns, then the row reflects
  the new effective prefs immediately and a success state is announced.
- Given reset-to-default, when applied, then override is cleared and effective
  prefs revert to the list default (US-055 AC3).
- Given a non-email channel toggle, when saved, then the preference is stored
  even though no delivery occurs on it this phase (US-052 AC2).

**Edge cases**: quiet period with no timezone → default zone used + shown
(US-053 AC3); pause date in the past → rejected with announced error; concurrent
edit (list default changed) → server re-resolves effective prefs on save so
explicit overrides survive (US-055 AC2).

**Related stories**: US-063, US-051, US-052, US-053, US-055, US-056, US-057.
**Expected tests**: 10–14.

---

### FR-006: Contact-preference mutation endpoint (backend)

**Status**: Draft — **should**

**Description**: Authed endpoint to update a single signup's contact preferences
or reset them.

**Interface**:
```
PATCH /api/v1/me/signups/:id
body: {
  contact_prefs?: ContactPrefs,   // partial override merge
  pause_until?: ISO8601 | null,
  reset_to_default?: true          // sets contact_prefs = NULL
}
200 => { signup: SignupView }      // effective prefs recomputed
```
Controller: extend the Chunk B `/me/signups` controller (`use ForyouWeb,
:controller`). Validate body; ownership check (`user_id == current_user.id ||
email == current_user.email`) else 404.

**Behavior**:
- Given a valid partial body, when PATCHed, then only supplied fields override;
  others are preserved; response carries recomputed effective prefs.
- Given `reset_to_default: true`, when PATCHed, then `contact_prefs` is nulled
  and the response reflects list defaults.
- Given `pause_until`, when set, then stored as timestamptz; the row's
  effective status shows `paused` until that time.
- Given a channel outside `available_channels`, when submitted, when saved,
  then it is forced `false` (never silently enabled).

**Edge cases**: unknown frequency value → 422; nonexistent `:id` or foreign
ownership → 404; archived list → 409/422 "list archived".

**Related stories**: US-063, US-051, US-052, US-053, US-055, US-056.
**Expected tests**: 8–10.

---

### FR-007: Re-subscribe and resume (could-have)

**Status**: Draft — **could** (deferrable without blocking the chunk gate)

**Description**: Let a user re-activate an unsubscribed signup or resume a
paused one.

**Interface**:
```
POST /api/v1/me/signups/:id/resubscribe  => { signup }   // 202 if re-confirm email queued
POST /api/v1/me/signups/:id/resume       => { signup }
```

**Behavior**:
- Given an unsubscribed subscription, when Re-subscribe is chosen, then it
  re-activates per the list's opt-in mode — double-opt-in lists send a fresh
  confirmation email and return the row to `pending_optin`; single-opt-in lists
  return to `subscribed` (US-066 AC1/AC3).
- Given a paused subscription, when Resume is chosen, then `pause_until` is
  cleared and contact resumes at prior prefs (US-066 AC2).
- Given re-confirm is queued, when triggered, then a fresh confirmation email is
  sent (via existing `noizu_sendgrid` + Oban `EmailWorker`).

**Edge cases**: list archived mid-resubscribe → 409; already active → idempotent
no-op.

**Related stories**: US-066, US-056. **Expected tests**: 5–7.

---

### FR-008: My inquiries view

**Status**: Draft — **should**

**Description**: A section showing the user's submitted inquiries with site,
date, summary, and status.

**Interface**: `api.getMyInquiries()` → `GET /api/v1/me/inquiries`. Render
`InquiryRow`s (site, date, summary, status badge). Section lives on the main
dashboard (or `/app/me/inquiries`, SCR-16).

**Behavior**:
- Given inquiries submitted with the user's email, when the dashboard opens,
  then each inquiry shows site, date, and content summary.
- Given an inquiry has a status, when rendered, then the status is shown via
  StatusBadge.
- Given no inquiries, when the section renders, then an appropriate empty state
  is shown (CMP-07).

**Edge cases**: very long inquiry text → truncated summary with title attribute;
inquiry with no matching service → "Other/legacy".

**Related stories**: US-065. **Expected tests**: 4–5. See **Open Questions**
for the legacy-inquiries-table coverage decision.

---

### FR-009: Export my data

**Status**: Draft — **should**

**Description**: Download a machine-readable file of the user's subscriptions,
preferences, and inquiries.

**Interface**:
```
GET /api/v1/me/export   => 200 JSON (Content-Disposition: attachment)
{ user: {email}, generated_at, signups: [...], inquiries: [...], contact_prefs_per_signup: {...} }
```

**Behavior**:
- Given a signed-in user, when they request export, then they receive a file
  containing **only** their own subscriptions, prefs, and inquiries.
- Given repeated rapid requests, when a per-user rate limit is exceeded, then
  the request is throttled (429) (US-067 AC3).

**Edge cases**: large dataset → stream/generate via Oban and deliver a download
link if synchronous is too slow (implementation choice; prefer simple sync JSON
unless N is large).

**Related stories**: US-067. **Expected tests**: 4–5.

---

### FR-010: Request account / data deletion (could-have)

**Status**: Draft — **could** (deferrable)

**Description**: A confirm flow to request erasure/anonymization of the user's
data per policy.

**Interface**:
```
POST /api/v1/me/deletion-request  body: { confirm: true } => 202 { status: "queued" }
```
UI: button in the privacy section (SCR-16) → ConfirmDialog (CMP-18) describing
what is removed → on confirm, POST → notice that the request is queued and any
legal-retention carve-out is communicated.

**Behavior**:
- Given a signed-in user, when they request deletion, then they are asked to
  confirm and told what will be removed.
- Given confirmation, when processed, then personal data is erased or
  irreversibly anonymized per policy (US-068 AC2).
- Given legal retention applies, when deletion runs, then only permissible data
  is retained and the user is informed.

**Edge cases**: outstanding obligations → partial retention surfaced honestly;
repeated requests → dedupe (one queued request at a time).

**Related stories**: US-068. **Expected tests**: 4–6.

---

### FR-011: Empty state

**Status**: Draft — **should**

**Description**: When the user has no subscriptions or inquiries, show an
explanatory empty state instead of a blank page.

**Behavior**:
- Given no subscriptions and no inquiries, when the page opens, then an
  explanatory empty state renders (CMP-07) explaining subscriptions appear here
  after signing up on a site.
- Given the user later signs up somewhere, when they return, then the new
  subscription appears (post-reconcile).

**Related stories**: US-070. **Expected tests**: 3.

---

### FR-012: Accessibility & low-bandwidth

**Status**: Draft — **should**

**Description**: The whole preference center is keyboard-operable, has announced
state changes, and renders progressively on slow connections. WCAG 2.1 AA.

**Behavior**:
- Given the dashboard, when navigated by keyboard, then all groups,
  subscriptions, and actions are reachable and labeled.
- Given an unsubscribe/preference change, when it completes, then the result is
  announced via a live region (`aria-live`).
- Given the page loads on a slow connection, when content arrives, then it
  renders progressively (skeletons → content) and remains usable.
- Given a save error, when it occurs, then it is announced and **not** conveyed
  by color alone.

**Related stories**: US-069, US-057. **Expected tests**: 4–6.

---

## Frontend specification

### Routes

| Route | Screen | Purpose |
|---|---|---|
| `/app/me` | SCR-14 | Dashboard: subscriptions grouped by service + inquiries summary. |
| `/app/me/inquiries` | SCR-16 | Full inquiries list + privacy (export/deletion). |
| `/app/me` modal | SCR-15 | Per-subscription contact-preference editor (CMP-13). |

`/app/me` is a **sibling of `/app/[orgId]`**, not nested under it — the
preference center is account-scoped and must render with no org selected. Add a
persistent **"My preferences"** entry in the app shell / navbar
(`src/components/navbar.tsx`) and in `org-switcher.tsx` so it is reachable from
any org context. It must **not** require an org in the URL.

### Data fetching (`src/lib/api.ts`)

Add to the `api` object, using the existing `request<T>` helper (bearer token +
automatic 401 refresh at `api.ts:73`):

```ts
getMySignups: () => request<{ signups: SignupView[] }>("/api/v1/me/signups"),
getMyInquiries: () => request<{ inquiries: InquiryView[] }>("/api/v1/me/inquiries"),
unsubscribeMySignup: (id: string) =>
  request<{ id: string; status: string }>(`/api/v1/me/signups/${id}`, { method: "DELETE" }),
updateMySignupPrefs: (id: string, body: ContactPrefsBody) =>
  request<{ signup: SignupView }>(`/api/v1/me/signups/${id}`, { method: "PATCH",
    body: JSON.stringify(body) }),
resubscribeMySignup: (id: string) =>
  request<{ signup: SignupView }>(`/api/v1/me/signups/${id}/resubscribe`, { method: "POST" }),
resumeMySignup: (id: string) =>
  request<{ signup: SignupView }>(`/api/v1/me/signups/${id}/resume`, { method: "POST" }),
exportMyData: () => request<MyExport>("/api/v1/me/export"),
requestDeletion: () =>
  request<{ status: string }>("/api/v1/me/deletion-request", { method: "POST",
    body: JSON.stringify({ confirm: true }) }),
```

Fetch on mount with `Promise.all` (parallel). Use optimistic UI for
unsubscribe/pause/resume with rollback on error.

### Components (reuse design system)

| Component | Use |
|---|---|
| **CMP-14 SubscriptionList** | groups + rows + actions (heart of SCR-14). |
| **CMP-13 PreferenceControls** | the editor modal (SCR-15). |
| **CMP-10 StatusBadge** | subscription/inquiry status. |
| **CMP-07 EmptyState** | no-subscriptions/no-inquiries. |
| **CMP-18 ConfirmDialog** | unsubscribe + deletion confirm. |
| **CMP-04 InlineAlert** | save state, deferred-channel notice, errors. |
| **CMP-09 SummaryCard** | dashboard summary (e.g. "N subscriptions across M sites"). |
| **CMP-08 EntitySwitcher** | (ServiceSwitcher) cross-site context, reused. |

### Design-system presentation (`sg-*`)

Use existing `sg-*` classes — do **not** introduce one-off styles. Specifically:
page shell via `sg-page-title` / `sg-section-heading`; groups via
`sg-group-content-padding`; rows via `sg-table`; actions via `sg-btn`,
`sg-btn--outline`, `sg-btn--sm`; form fields via `sg-field`; errors via
`sg-error`; borders via `sg-border`. Match the de-inlined admin pages' class
discipline (Chunk A set this pattern). Verify against
`app/frontend/src/app/styleguide`.

### Accessibility

All interactive elements keyboard-reachable with visible focus; status changes
in an `aria-live="polite"` region; toggle/checkbox state announced; errors
announced with text (not color alone). See FR-012.

---

## Error Handling

| Condition | Backend | Frontend |
|---|---|---|
| Unauthenticated | 401 | redirect `/login?next=/app/me` (via existing refresh/retry) |
| Signup not found / not owned | **404** (no leak) | remove row + announce; no stack trace |
| Invalid preference value (e.g. bad frequency) | 422 + `{error}` | InlineAlert, keep editor open |
| List archived (mutate/resubscribe) | 409/422 | announce "list no longer available"; hide action |
| Rate limited (export) | 429 | InlineAlert "try again shortly" |
| Network failure | — | InlineAlert + retry; never show false success |

Generic errors follow the existing `request<T>` error extraction
(`body.error || body.errors?.email?.[0]`, `api.ts:122`).

---

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Test coverage for new backend code | Line coverage | >= 80% |
| NFR-2 | Frontend type-safety | `tsc` errors | 0 (`npm run build` green) |
| NFR-3 | Dashboard initial load | Time to interactive | < 1.5s on slow 3g (progressive render) |
| NFR-4 | No-leak posture | Foreign-id response | 404, never 403 |
| NFR-5 | Accessibility | WCAG | 2.1 AA |

---

## Acceptance Tests

| ID | Title | Category | FR | Stories | Status |
|----|-------|----------|----|---------|--------|
| AT-001 | Authenticated dashboard loads subscriptions + inquiries | integration | FR-001 | US-061 | Not started |
| AT-002 | Unauthenticated redirect to login with `next` | unit | FR-001 | US-061 | Not started |
| AT-003 | Subscriptions grouped by service; single-group clean | unit | FR-002 | US-064 | Not started |
| AT-004 | Row shows service/list/status/date + actions | unit | FR-003 | US-061 | Not started |
| AT-005 | Unsubscribe → status `unsubscribed`, announced, idempotent | e2e | FR-004 | US-062 | Not started |
| AT-006 | Authed unsubscribe matches token-unsubscribe end-state | integration | FR-004 | US-062 | Not started |
| AT-007 | Editor shows effective prefs; only offered channels selectable | unit | FR-005 | US-063, US-052 | Not started |
| AT-008 | Save persists override; effective prefs recomputed | integration | FR-005, FR-006 | US-051, US-055 | Not started |
| AT-009 | Reset-to-default clears override → list default | integration | FR-005, FR-006 | US-055 | Not started |
| AT-010 | Quiet period stored with timezone default | unit | FR-005 | US-053 | Not started |
| AT-011 | Non-email channel stored but flagged deferred | unit | FR-005 | US-052 | Not started |
| AT-012 | Pause sets `pause_until`; row shows paused; resume clears | integration | FR-005, FR-007 | US-056, US-066 | Not started |
| AT-013 | PATCH rejects unknown freq / foreign id (404) | unit | FR-006 | US-051 | Not started |
| AT-014 | Re-subscribe respects double/single opt-in | integration | FR-007 | US-066 | Not started |
| AT-015 | My inquiries render site/date/summary/status | unit | FR-008 | US-065 | Not started |
| AT-016 | Export returns only my data; throttled on repeat | integration | FR-009 | US-067 | Not started |
| AT-017 | Deletion request is confirm-flow + queued | integration | FR-010 | US-068 | Not started |
| AT-018 | Empty state renders when nothing exists | unit | FR-011 | US-070 | Not started |
| AT-019 | Full keyboard nav + live-region announcements | e2e | FR-012 | US-069, US-057 | Not started |
| AT-020 | Progressive render under slow connection | e2e | FR-012 | US-069 | Not started |

Each AT maps 1:1 to a story AC group above and follows the project AT template
(`acceptance-tests/AT-NNN-*.md`) when the implementer scaffolds the suite.

---

## Success Criteria

1. US-061, US-064, US-062, US-051, US-052 (must-have) fully implemented with ACs passing.
2. All should-have stories implemented; could-have (US-066/056/068) either done or explicitly deferred in tracking.
3. `npm run build` is green (0 `tsc` errors); `mix test` green for new backend.
4. Smoke (claude-in-chrome): sign in → `/app/me` shows cross-site subscriptions grouped by service; unsubscribe updates the row; editor saves frequency; inquiries render; empty state shows for a fresh account.
5. WCAG 2.1 AA on the dashboard + editor; no-leak 404 on foreign ids.
6. Post-M5 multi-channel senders remain untouched (no partial sending code shipped).

---

## Dependencies & Cross-Chunk Boundaries

- **Chunk B (hard dependency)** — `lists` (026), `signups` (027), the public
  signup endpoint, token unsubscribe, reconcile-on-login worker, and the
  `/me/signups` + `/me/inquiries` + `DELETE /me/signups/:id` endpoints. Chunk E
  cannot start until these land.
- **Chunk B schema coordination** — confirm whether 027-signups already adds
  `contact_prefs`; Chunk E's `029-contact-preferences` adds only what is
  missing. Single-owner hotspot: the Liquibase master include.
- **Chunk D (boundary)** — owns the Service-editor **list-default editor UI**
  (US-054 editor surface, SCR-08). Chunk E defines the **shared storage
  contract** (`lists.settings.contact_prefs` + `available_channels`) so both
  sides agree on inheritance; Chunk E does not build the editor UI.
- **Token unsubscribe (Chunk B)** — authed unsubscribe must produce identical
  end-state (AT-006).
- **Mailer** — reuse `noizu_sendgrid` + Oban `EmailWorker` for re-subscribe
  confirmation emails (FR-007).
- **CORS** — not in scope (the preference center is same-origin from
  `foryou.therobotlives.com`).

---

## Open Questions

1. **Legacy inquiries coverage (affects US-065 / FR-008).** `/me/inquiries` is
   specified as "signups where `list.kind IN ('inquiry','contact')`". The legacy
   `inquiries` table (changelog 025) holds pre-dual-write noizu.com submissions
   that may have **no** matching signup row. Should `/me/inquiries` also UNION
   legacy `inquiries`-table rows matched by email (so historical submissions
   appear), or show only inquiry-kind signups (post-dual-write going forward)?
   *Recommendation: UNION legacy rows by email so the history is complete; mark
   them with a `source: "legacy"` flag.* — **needs decision.**
2. **Contact-prefs column home.** Confirm Chunk B's 027-signups has not already
   added `contact_prefs`/`pause_until`; if it has, drop those from 029 to avoid
   duplicate-column migrations. — **verify against Chunk B PRD.**
3. **Export delivery model.** Synchronous JSON attachment vs. Oban-generated
   download link for large datasets. *Recommendation: synchronous now, Oban
   later if N grows.* — **confirm acceptable.**
4. **Deletion fulfilment.** FR-010 queues a request; the actual erasure job +
   retention policy live outside this chunk. Is a stub queuer + honest "queued"
   notice acceptable for M3, with fulfilment wired in a later milestone?
   *Recommendation: yes.* — **confirm acceptable.**
5. **`/app/me` route placement.** Decided: account-scoped sibling of
   `[orgId]` (not nested). Confirm this matches the app-shell guard model (the
   shell must not force an org for `/app/me`).
