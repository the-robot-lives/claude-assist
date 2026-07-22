---
id: US-011
title: "Personal todos with due date, tags, and recurrence"
lane: WS-A
milestone: M1
size: M
personas: [raj-patel]
domain: personal
status: draft
author: Loom (WS-A PRD pass)
generated: 2026-07-22
depends_on:
  - ch034 (item rank/start_date/due_date/estimate + item_events baseline)
  - Domains.Items context (create/update/list/complete substrate)
  - users table (owner FK), Therobotplans.Authz, Oban
migration_block: 100-104 (WS-A / M1)
---

# US-011 — Personal todos with due date, tags, and recurrence

## 1. Overview & goal

### Goal
Let a user maintain a first-class **personal todo list** inside their org — items with a
**due date**, free-form **tags**, and optional **recurrence** — using the *same* polymorphic
`items` substrate that backs project tasks, epics, and bugs. A "personal todo" is not a new
entity: it is an `items` row scoped to a user (`owner_user_id`), not to a project
(`project_id IS NULL`), with `item_type = "todo"`. This story is the foundational CRUD
vertical for the WS-A (Personal Items & Habits) lane; habits (US-012), streaks (US-014),
smart lists (US-015), life-alongside-work (US-016), time-blocking (US-017), and archive
(US-020) all extend it.

### Persona — Raj Patel (Solo Developer / Side-Project Builder)
Raj tracks day-job obligations in Jira, personal life in Apple Reminders, and side projects
poorly in GitHub Issues. He wants **one view** with low ceremony: a list he can dump both
one-off tasks ("apartment viewing 6pm") and repeating obligations ("gym 3×/week", "daily
standup") into, tagged and due-dated, so he can make honest tradeoff decisions. He travels,
so due-date math must be timezone-correct.

### Jobs-to-be-done
- "When I have an idea or obligation, capture it in seconds with a due date and a tag."
- "My repeating chores should regenerate themselves when I finish them — I shouldn't retype
  'gym' three times a week."
- "Show me what's overdue and what's due today, above everything else."
- "Let me find every item — personal or project — tagged `#cli-tool` in one search."

---

## 2. Functional requirements (expanded AC)

Story AC bullets are marked **[AC-n]**; expanded edge behavior follows each.

**FR-1 — Create with due date, tags, recurrence [AC-1].**
Creating a personal item accepts: `title` (required), `due_date` (optional), `tags` (0..n
free-form strings), `recurrence` (optional rule), `priority` (optional). Due date accepts an
ISO `YYYY-MM-DD` **or** a minimal relative phrase (`today`, `tomorrow`, `next <weekday>`,
`in N days`) resolved server-side in the user's timezone (§4 `parse_shorthand/2`). Full NLP
("the second Thursday after payday") is out of scope.
- Edge: creating with a recurrence but **no anchor date** (no `due_date`/`dtstart`) is
  rejected with a 422 — a recurrence needs a start anchor.
- Edge: empty/whitespace tags are dropped; tags are lower-cased and de-duplicated on write.

**FR-2 — Recurrence options [AC-2].**
Supported presets: `daily`, `weekdays` (Mon–Fri), `weekly`, `biweekly` (every 2 weeks),
`monthly`, and `custom`. Presets compile to the `recurrence_rules` shape (§3). `custom`
exposes the raw fields (`freq`, `interval`, `by_day`, `by_month_day`, `until`, `count`).
- `weekdays` = `freq=weekly, by_day=[MO,TU,WE,TH,FR]`.
- `biweekly` = `freq=weekly, interval=2`, anchored on the item's due weekday.
- `monthly` defaults to `by_month_day=[day-of-anchor]`; month-end anchors clamp
  (Jan 31 → Feb 28/29). See FR-4 clamp rule.

**FR-3 — Auto-generate next occurrence on completion [AC-3].**
Completing a recurring item (a) sets the completed item's `status = "done"`, and (b)
**materializes the next occurrence** as a new `items` row cloning `title`, `tags`,
`owner_user_id`, `item_type`, `priority`, and `recurrence_rule_id`, with `due_date` =
`Recurrence.next_occurrence/2` and `recurrence_parent_id` linking it to the series seed
(§4). The two-row (completed + next) result is returned by the complete endpoint.
- Edge — **series exhausted**: if the rule's `until` has passed or `count` is reached,
  completion closes the item and generates **no** successor (`next: null`).
- Edge — **skipped recurrence**: an occurrence that passes its `due_date` without completion
  does **not** pile up missed instances. Default behavior: it stays as a single overdue
  occurrence. A per-rule opt-in flag `roll_on_skip` (default `false`, used by habits US-012)
  lets a nightly sweep advance it forward instead (§4 sweep worker).
- Edge — completing a **non-recurring** item: normal close, no successor.
- Idempotency: completing an already-`done` item is a no-op (no duplicate successor).

**FR-4 — Overdue & grouping [AC-4].**
The list is grouped into four buckets, computed against **"today" in the user's timezone**:
- **Overdue** — `status = "open"` AND `due_date < today_local`.
- **Today** — `due_date = today_local`.
- **Upcoming** — `due_date > today_local`.
- **Someday** — `due_date IS NULL`.
Overdue items render a visual indicator (color shift + badge) and sort to the top of the
Today view aggregation (US-001 consumes this ordering). Month-end clamp: when advancing a
monthly rule, if the target month has fewer days than `by_month_day`, use the last day of
that month.

**FR-5 — Tags: free-form, cross-scope, searchable [AC-5].**
Tags are stored as a first-class `items.tags text[]` column (see §3 / §8 rationale — a
dedicated column, **not** a `multi_select` custom field). Tags are:
- user-defined and free-form (no controlled vocabulary, no definition edit to add a new tag);
- searchable across **all** items in the org (personal and project) via a GIN index;
- surfaced for autocomplete via an org-scoped distinct-tag query;
- filterable: `GET .../personal/items?tag=cli-tool` (AND-semantics when repeated).
- Edge — tag CRUD on an item: add/remove is a `PATCH` replacing the `tags` array. Renaming a
  tag across items (bulk) is **out of scope** for MVP (open question OQ-6).

**FR-6 — Drag reorder within a group [via ch034 rank].**
Manual ordering uses the existing `items.rank` lexorank column. Reorder is a `PATCH` setting
`rank` to a midpoint string between the dropped item's new neighbors (client computes or
requests a server midpoint). Ordering is scoped within a bucket for a given owner; default
sort within a bucket is `due_date ASC NULLS LAST, rank ASC`.

**FR-7 — Personal vs project scoping boundary.**
A **personal** item (`owner_user_id = current_user AND project_id IS NULL`) never appears on
a project board; a **project** item never appears in the personal list. The personal list is
strictly `owner_user_id = current_user` within the org. Cross-scope leakage is a defect
(test T-9).

---

## 3. Data model

Migrations occupy the **WS-A / M1 block 100–104** (roadmap scheme: `Mx → x00 + lane offset`;
WS-A offset 00–04). The base `items` table already exists (ch026) and ch034 already added
`rank/start_date/due_date/estimate` + `item_events`; **no new base-items migration is
needed** — US-011 adds only ownership, tags, and recurrence. Each changelog is registered in
the WS-A lane include; the master include edit is a WS-L touchpoint (OQ-1).

### ch100 — `100-personal-item-ownership-and-tags.yaml`
Adds per-user ownership and first-class tags to `items`.
```sql
ALTER TABLE items
  ADD COLUMN owner_user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  ADD COLUMN tags varchar[] NOT NULL DEFAULT '{}';

-- Personal list query: owner + due-date bucketing, org-scoped.
CREATE INDEX idx_items_owner_due
  ON items (organization_id, owner_user_id, due_date)
  WHERE owner_user_id IS NOT NULL;

-- Cross-scope tag search + autocomplete (personal AND project items).
CREATE INDEX idx_items_tags_gin ON items USING gin (tags);
```
- `owner_user_id` is nullable: project items keep it NULL. **Personal item ⇔
  `owner_user_id IS NOT NULL AND project_id IS NULL`.** Chosen over a boolean `personal`
  flag or a `scope` enum because the discriminator must also answer *whose* personal list it
  is; `owner_user_id` does both (see §8 rationale). `users(id)` is confirmed `uuid`.
- Rollback: drop both indexes, drop both columns.

### ch101 — `101-recurrence-rules.yaml`
Simplified RFC-5545-flavored rule (subset sufficient for the six presets + custom).
```sql
CREATE TABLE recurrence_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  freq varchar NOT NULL,            -- 'daily' | 'weekly' | 'monthly'
  interval integer NOT NULL DEFAULT 1,   -- every N freq units
  by_day varchar[],                 -- ['MO','TU',...] (weekly)
  by_month_day integer[],           -- [1..31, -1 for last] (monthly)
  by_month integer[],               -- optional [1..12]
  dtstart date NOT NULL,            -- anchor
  until date,                       -- inclusive end (nullable)
  count integer,                    -- max occurrences (nullable)
  timezone varchar NOT NULL DEFAULT 'Etc/UTC',  -- user tz at creation
  roll_on_skip boolean NOT NULL DEFAULT false,  -- habits opt-in (FR-3)
  inserted_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_recurrence_rules_org ON recurrence_rules (organization_id);
```
- `freq` limited to `daily|weekly|monthly`; `weekdays`/`biweekly`/`weekly` all resolve onto
  `weekly` with `by_day`/`interval`. `until` XOR `count` (or neither = open-ended);
  validated in the changeset, not the DB.

### ch102 — `102-item-recurrence-link.yaml`
Links an item to its rule and its series lineage.
```sql
ALTER TABLE items
  ADD COLUMN recurrence_rule_id uuid REFERENCES recurrence_rules(id) ON DELETE SET NULL,
  ADD COLUMN recurrence_parent_id uuid REFERENCES items(id) ON DELETE SET NULL;

-- Series history / streak scans (US-012, US-014) walk the lineage.
CREATE INDEX idx_items_recurrence_parent ON items (recurrence_parent_id);
```
- The active open occurrence carries `recurrence_rule_id`. All occurrences of a series share
  `recurrence_parent_id` = the seed item's id (seed's own `recurrence_parent_id` is NULL;
  treat NULL-with-a-rule as its own seed). This gives O(1) history retrieval and streak math
  without a separate occurrences table.
- **ch103 / ch104 reserved** (unused; e.g. a future `recurrence_completions` materialized
  view if streak queries need denormalizing — not built here).

### Ecto schema changes
- `Therobotplans.Schema.Item` — add fields `owner_user_id :binary_id`, `tags {:array,
  :string}` default `[]`, `recurrence_rule_id :binary_id`, `recurrence_parent_id
  :binary_id`; `belongs_to :recurrence_rule`. Cast/validate the new fields; `tags` cleaned
  (trim, downcase, uniq) in the changeset.
- New `Therobotplans.Schema.RecurrenceRule` schema for `recurrence_rules`.
- `item_events` remains schema-less raw insert (ch034 convention); add `owner_user_id` and
  `due_date` to nothing — `due_date` is already an event-tracked field candidate; extend the
  tracked-field list (items.ex ~215) to include `due_date` and `tags` so recurrence advances
  and tag edits land in the audit trail.

---

## 4. Recurrence engine design

Module: **`Therobotplans.Domains.Personal.Recurrence`** (pure date math, no Repo) plus
orchestration in **`Therobotplans.Domains.Personal`** (the lane's facade over
`Domains.Items`).

### Pure functions (`Domains.Personal.Recurrence`)
```elixir
@doc "Next occurrence strictly after `from`, in the rule's timezone. `:series_complete`
      when until/count exhausted."
@spec next_occurrence(RecurrenceRule.t(), from :: Date.t()) ::
        {:ok, Date.t()} | :series_complete | {:error, term}

@doc "All occurrences within an inclusive date range (calendar/preview; US-017)."
@spec expand(RecurrenceRule.t(), Date.Range.t()) :: [Date.t()]

@doc "Compile a preset name to rule attrs given an anchor date + tz."
@spec preset_to_rule(preset :: String.t(), anchor :: Date.t(), tz :: String.t()) ::
        {:ok, map} | {:error, :unknown_preset}
  # daily | weekdays | weekly | biweekly | monthly | custom

@doc "Minimal relative-date parser, resolved in tz (today, tomorrow, next <wd>, in N days)."
@spec parse_shorthand(String.t(), tz :: String.t()) :: {:ok, Date.t()} | {:error, term}
```

**Timezone rule.** `due_date` is a bare `date` (no clock time). To avoid the classic UTC
off-by-one (midnight-UTC rolling the calendar day for a user in UTC−6), all "today" and
"next weekday" computations resolve `DateTime.now(rule.timezone || user_tz)` → `Date`, do the
interval arithmetic on that local `Date`, and return a `Date`. `next_occurrence/2` for
`freq=weekly` walks forward day-by-day from `max(from, dtstart)` to the next date whose
weekday ∈ `by_day` respecting `interval` week-count from `dtstart`; `monthly` adds
`interval` months to the anchor and clamps `by_month_day` to the month length (FR-4). Uses
`tzdata` (already a transitive dep via Timex/Elixir tz db — confirm in mix, OQ-4).

### Orchestration (`Domains.Personal`)
```elixir
@doc "Complete an item; if recurring and series not exhausted, materialize the next
      occurrence. Returns both rows."
@spec complete_item(item_id :: binary, actor :: String.t()) ::
        {:ok, %{completed: Item.t(), next: Item.t() | nil}} | {:error, term}
```
`complete_item/2` runs in a transaction: mark `status="done"`; if `recurrence_rule_id`
present → `next_occurrence/2`; on `{:ok, date}` insert the successor (clone via
`Domains.Items.create/1`) with `recurrence_parent_id = item.recurrence_parent_id || item.id`;
write `item_events` for both. `:series_complete` → no successor.

### When it fires
- **Primary — on complete (synchronous).** Satisfies AC-3 immediately and is the only path
  needed for MVP correctness.
- **Secondary — nightly Oban cron** `Therobotplans.Workers.RecurrenceSweepWorker` (fits the
  existing `workers/` dir alongside `email_worker`, `cleanup_worker`). Only acts on rules
  with `roll_on_skip = true`: advances an untouched overdue habit forward so it doesn't sit
  as a stale overdue row. For MVP US-011 (`roll_on_skip` default false) the sweep is a no-op
  hook; US-012 turns it on. Requires an `Oban.Plugins.Cron` entry — that config edit is a
  platform/WS-L touchpoint (OQ-1); ad-hoc `Oban.insert` works regardless.

---

## 5. API surface

New controller **`TherobotplansWeb.PersonalItemController`** (WS-A owns
`domains/personal`; it delegates to the shared `Domains.Items` context). Routes live under
the existing authenticated org scope; **adding the route block edits `router.ex` = WS-L
hotspot → file an interface ticket to WS-L** (do not edit directly). Proposed block:

```
scope "/api/v1/organizations/:org_id/personal", TherobotplansWeb do
  pipe_through [:api, :authenticated]
  get    "/items",              PersonalItemController, :index
  post   "/items",             PersonalItemController, :create
  patch  "/items/:id",         PersonalItemController, :update
  post   "/items/:id/complete", PersonalItemController, :complete
  post   "/items/:id/recurrence",   PersonalItemController, :set_recurrence
  delete "/items/:id/recurrence",   PersonalItemController, :clear_recurrence
end
```

Follows the `ItemController` conventions verbatim: `user_id` from
`Therobotplans.Guardian.Plug.current_resource`; authz via
`Therobotplans.Authz.authorize(user_id, "organization", org_id, role)` — `role="viewer"` for
`index`, `role="member"` for writes; **plus an ownership guard**: every action asserts the
target item's `owner_user_id == user_id` (personal items are private to their owner even
within an org). Hand-rolled `item_to_json/1` extended with `tags`, `due_date`,
`recurrence` (embedded rule summary), `overdue` (computed bool), `bucket`.

| Action | Method/Path | Body | Success |
|---|---|---|---|
| index | `GET /items?group=&tag=&status=&q=` | — | `200 {groups: {overdue,today,upcoming,someday}}` or `{items}` when `group=all` |
| create | `POST /items` | `{"item":{title,due_date,tags[],priority,recurrence{...}}}` | `201 {item}` |
| update | `PATCH /items/:id` | `{"item":{title?,due_date?,tags?,rank?,status?,priority?}}` | `200 {item}` |
| complete | `POST /items/:id/complete` | — | `200 {completed, next}` |
| set_recurrence | `POST /items/:id/recurrence` | `{"recurrence":{preset\|freq,interval,by_day,...}}` | `200 {item}` |
| clear_recurrence | `DELETE /items/:id/recurrence` | — | `200 {item}` |

`:id` accepts a UUID or the human key (reuse `fetch_item`). `422` on invalid recurrence /
missing anchor / bad date; `403` on ownership or role failure; `404` on cross-owner id.

**MCP (idiomatic, optional for MVP).** A `personal.` host MCP server mirroring the items
pattern (§ scout finding 5): tools `Personal.Item.Create`, `Personal.Item.Complete`,
`Personal.Item.SetRecurrence`, `Personal.Item.List` — one module per tool under
`domains/personal/tools/`, `use Noizu.MCP.Server.Tool`, `input_schema/1`, `call/2` returning
`{:ok, map}`. Enables Raj's "planner agent" (US-018) to triage personal items. Recommend
landing at least `Personal.Item.List` in M1 so the agent read-path exists; the rest can defer
to US-018.

---

## 6. Frontend

New route **`app/frontend/src/app/app/[orgId]/personal/page.tsx`** (WS-A owns
`app/[orgId]/personal/**` and `components/personal/**`; the route does not exist yet). Next.js
16 app router, client components where interactive.

### Layout
A single-column list grouped by **Overdue / Today / Upcoming / Someday** (FR-4), each a
`SectionCard` from `@/components/ui`. Overdue header + rows carry a red accent + `StatusBadge`
"Overdue". An inline **create row** pinned at the top: title `Input`, `DueDatePicker`,
`TagChips`, `RecurrencePicker`, submit `Button`. Empty groups collapse; fully empty list shows
`EmptyState`.

### New components (`src/components/personal/`)
- `PersonalItemList` — orchestrates groups, drag-reorder (rank), optimistic complete.
- `PersonalItemRow` — title, due badge, tag chips, recurrence glyph, complete checkbox,
  overflow menu (edit/delete/set-recurrence). Mirrors the inline item rendering in
  `items/page.tsx` (reuse `PriorityBadge`/`StatusBadge` from `@/components/pm/priority-badge`);
  no shared `ItemCard` exists yet, so this row is the personal-lane equivalent.
- `DueDatePicker` — native date input + relative-phrase text entry (posts raw string; server
  resolves via `parse_shorthand`).
- `TagChips` — free-form chip input with org-scoped autocomplete (distinct tags endpoint).
- `RecurrencePicker` — `Select` of presets (None/Daily/Weekdays/Weekly/Biweekly/Monthly/
  Custom); Custom expands to interval + weekday toggles + until/count via `Dialog`.

### Data
Extend `src/lib/api.ts` (additive; not a WS-L hotspot) with `listPersonalItems`,
`createPersonalItem`, `updatePersonalItem`, `completePersonalItem`, `setRecurrence`,
`clearRecurrence`, plus a `PersonalItem`/`RecurrenceRule` TS type. Use `useApi` for the list
(`{data,error,loading,mutate}`) and `useMutation` (with `optimistic`) for create / complete /
reorder so the checkbox and drag feel instant, reverting on error. Org id via `useOrg()`.

Reuse: `@/components/ui` barrel (`Button, Input, Select, Textarea, SectionCard, EmptyState,
Spinner, Dialog, PriorityBadge, StatusBadge`). No new UI primitives required.

---

## 7. Acceptance tests

Backend (ExUnit; `Domains.Personal` + `Recurrence` + controller) and FE (component/e2e).

**Recurrence math (`Recurrence.next_occurrence/2`)**
- T-1 daily: `daily` from 2026-07-22 → 2026-07-23.
- T-2 weekdays: from Fri 2026-07-24 → Mon 2026-07-27 (skips weekend).
- T-3 weekly by_day: `weekly by_day=[TU]` from Tue 07-21 → Tue 07-28.
- T-4 biweekly: `weekly interval=2` from 07-22 → 08-05 (not 07-29).
- T-5 monthly clamp: `monthly by_month_day=[31]` from 2026-01-31 → 2026-02-28.
- T-6 until exhausted: rule `until=2026-07-22`, complete on 07-22 → `:series_complete`.
- T-7 count exhausted: `count=3` after 3 materializations → `:series_complete`.
- T-8 timezone boundary: user tz `America/Chicago`, "today" near UTC midnight resolves to the
  local calendar day, not the UTC day (no off-by-one).

**Scoping & CRUD**
- T-9 scope boundary: a project item (`project_id` set) is absent from `GET /personal/items`;
  a personal item is absent from the project board list. Cross-owner GET → 404.
- T-10 ownership guard: user B `PATCH`ing user A's personal item → 403.
- T-11 create rejects recurrence without an anchor date → 422.
- T-12 tags normalized: create with `["CLI ", "cli", "Side"]` stores `["cli","side"]`.

**Overdue / grouping**
- T-13 grouping: seed items due yesterday/today/tomorrow/none → land in
  overdue/today/upcoming/someday respectively (computed in the request user's tz).
- T-14 overdue flag: an open item due < today has `overdue=true`; a `done` item due in the
  past has `overdue=false`.

**Completion & recurrence lifecycle**
- T-15 complete recurring: completing sets original `done`, returns `next` with correct
  `due_date`, shared `recurrence_parent_id`, same tags/owner/rule.
- T-16 complete non-recurring: `next=null`, original `done`.
- T-17 idempotent complete: completing an already-`done` item creates no second successor.
- T-18 skip default: an overdue recurring item with `roll_on_skip=false` is NOT advanced by
  the sweep worker; with `roll_on_skip=true` it advances one occurrence.

**Tags search / filter**
- T-19 cross-scope tag search: `?tag=cli-tool` returns both a personal and a project item
  bearing that tag (GIN-indexed path).
- T-20 tag autocomplete: distinct-tags endpoint returns the org's tag set.

**Reorder**
- T-21 drag reorder: `PATCH rank` to a midpoint reorders within a bucket and persists;
  subsequent list reflects `due_date ASC NULLS LAST, rank ASC`.

**Frontend**
- T-22 inline create renders the item optimistically and reconciles on server response.
- T-23 completing via checkbox removes/greys the row and (if recurring) shows the regenerated
  occurrence in its new bucket without a full reload.

---

## 8. Dependencies, out-of-scope, decisions, open questions

### Dependencies
- **ch034** (rank/start_date/due_date/estimate + `item_events`) — assumed landed (task #1,
  M1 backend, in progress). US-011 builds directly on `due_date`/`rank`.
- **`Domains.Items`** context — `create/1`, `update/3`, `list/1` (already supports list-valued
  filters → `IN`, ready for multi-value tag filtering), status-based completion.
- **`users` table** — `owner_user_id` FK (`users(id)` confirmed `uuid`).
- **`Therobotplans.Authz`** + Guardian — role checks + current user.
- **Oban** (`~> 2.18`, present) — sweep worker (secondary path only).
- **NOT dependent on the custom-fields/Definitions system.** Tags deliberately use a
  first-class column, not `multi_select` (rationale below), removing a coupling the task
  flagged as possible.

### Key decision — tags: dedicated `tags text[]` column, not `multi_select` custom field
The custom-field system *does* offer a `multi_select` type, but it is designed for
**controlled vocabularies** (fixed option lists resolved per (org, project) scope) with values
buried in the `items.custom_fields` jsonb. AC-5 requires the opposite: **free-form**
user-defined tags, **searchable across every item** in the org regardless of scope. A
`text[]` column with a single GIN index delivers free-form entry (no definition edit per new
tag), one index powering both cross-scope filter and `SELECT DISTINCT unnest(tags)`
autocomplete, and first-class query ergonomics — where a multi_select would force
definition-management overhead and jsonb-path indexing for what is conceptually a label set.
The lane can still expose a curated `multi_select` field later for structured taxonomies; the
two are complementary.

### Key decision — personal scoping via `owner_user_id`, not a `personal` flag / `scope` enum
The scoping discriminator must answer both *is this personal?* and *whose?*. A boolean
`personal` or a `scope` enum answers only the first and still needs an owner column. A single
nullable `owner_user_id` FK answers both: personal ⇔ `owner_user_id IS NOT NULL AND
project_id IS NULL`. Matches the story's "structurally the same entity … just lives in a
personal context."

### Out of scope
- Recurring **habits**, streaks, "skip vs miss" analytics (US-012 / US-014 — this PRD only
  lays the `roll_on_skip` flag + sweep hook).
- Smart lists / saved filters (US-015), time-blocking calendar expansion (US-017), archive
  view (US-020).
- Full natural-language date parsing beyond the minimal relative set.
- Bulk tag rename/merge across items.
- Unified Today dashboard aggregation (US-001, WS-L) — US-011 only exposes the read model it
  will consume.

### Open questions (for sign-off)
- **OQ-1 — migration slot 100 coordination.** Does `foundation`/WS-L reserve any of 100–104
  for a base-items or shared change? If ch100 collides, shift US-011 to 102–104. Also the
  master changelog include + `Oban.Plugins.Cron` config are WS-L edits — confirm the
  interface-ticket path.
- **OQ-2 — owner column on shared `items`.** ch100 alters the shared `items` table (owned
  conceptually by the items/foundation area, not WS-A's `domains/personal`). Confirm WS-A may
  own this migration or whether foundation should land `owner_user_id` as part of the M1 item
  baseline.
- **OQ-3 — instance-materialization vs advance-in-place.** This PRD recommends materializing a
  new occurrence on completion (keeps full history for streaks). Confirm with the habits owner
  (US-012 builds on this) before implementation, since the alternative (advance the same row's
  `due_date`) changes the schema (`recurrence_parent_id` unnecessary) and the streak query.
- **OQ-4 — timezone source & tz db.** Where does the user's timezone come from — a
  `users`/profile column, or the browser sending it per request? And confirm `tzdata` is
  available for `DateTime.now/1` on named zones.
- **OQ-5 — private-within-org semantics.** Are personal items strictly invisible to org
  admins/owners, or should an org-admin role bypass the ownership guard? PRD assumes strictly
  private to the owner.
- **OQ-6 — tag rename/merge** deferred; confirm acceptable for MVP.
