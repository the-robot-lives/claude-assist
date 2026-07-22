# PM Views — Design & Gap Reconciliation

**Status:** Draft v1 — 2026-07-22
**Scope:** The delivery-work surfaces of tobornalp: kanban board, swimlanes, scrum/sprint
board, gantt/timeline, backlog, calendar, filters & saved views, and the item detail that
feeds them all.
**Inputs:** 3-way audit (spec corpus `project-management/`, frontend `app/frontend/src`,
backend schema/API `app/backend`) run 2026-07-22. This doc reconciles the three and is the
engineering-facing design for closing the gap. It defers to existing screen specs
(`screens/13-kanban-board.md`, `14-sprint-planning`, `16-gantt-view`, `17-sprint-retro`,
`18-backlog-grooming`) for visual layout detail and to `roadmap/` for sequencing authority.

---

## 1. Where we actually are (3-way status matrix)

| Capability | Spec (stories/screens) | Frontend (shipped) | Backend (schema + API) |
|---|---|---|---|
| Kanban board | ✅ US-022, screen 13, comp 11 | 🟡 columns render; card move = `<select>`, no DnD, no filters, no board-create UI | 🟡 queues/stages/item↔stage fully wired; **no per-item rank** (renders `inserted_at desc`) |
| Swimlanes | 🟡 comp 33 exists; US-022 calls it "future" | ❌ none | ❌ no concept (single column axis) |
| Scrum sprints | ✅ US-023/027, screens 14/17 | ❌ `BoardIteration` types in api.ts, never fetched/rendered | 🟡 `board_iterations` table is sprint-shaped; stage/iteration CRUD **implemented in context but unexposed** (no route, no MCP tool) |
| Gantt / timeline | ✅ US-029/031, screen 16, comps 8/12 | ❌ none | 🟡 dependency edges perfect (`item_links` blocks/blocked_by); **no start/due date columns** |
| Backlog (ranked) | ✅ US-028, screen 18 | 🟡 unfiltered list capped at 40 inside `/items` | ❌ no rank column |
| Epics / hierarchy | ❌ no Epic story; label-only | ❌ `parent_id`/`item_type:epic` on types, zero UI | ✅ `items.parent_id` self-FK + `parent_of/child_of` links; `ItemList` filters by parent |
| Estimates / points | 🟡 AI-output only (US-023/028) | ❌ no field | 🟡 representable via custom fields (`number`); not queryable/sortable |
| Calendar | 🟡 US-017 is personal time-blocking only | ❌ none | 🟡 `due_date` exists as custom-field *convention* (Today already reads it) |
| Filters / saved views | ❌ zero "saved view" hits; FilterBar comp used on 17 screens | ❌ no filter UI at all | ❌ no table |
| Drag-drop reorder | ✅ US-003/022 | ❌ no DnD lib in package.json | ❌ blocked on rank column |
| Burndown / velocity | ❌ prose-only, no component | ❌ | ❌ no status-transition history to compute from |
| Comments / activity on items | ✅ (cross-cutting) | ❌ item detail has none | ✅ `trp_comments` (threaded) + attachments + watches + `ItemFeed` MCP |

**Read of the board:** the backend substrate is *ahead* of everything — epics, dependency
edges, methodology-aware boards, tri-scoped custom fields, threaded comments all exist and
are reachable today. The shipped UI is a thin walking skeleton. The spec corpus covers most
views but has four genuine holes: **saved views, manual estimation, burndown, committed
swimlanes** (plus Epic-as-first-class-UX). The fastest path to "elegant PM tool" is mostly
frontend work over existing endpoints, plus **three narrow, additive backend changes**.

---

## 2. The unifying design concept: one work graph, five projections

Items form a single graph (hierarchy via `parent_id`, dependencies via `item_links`,
membership via `queue_id`/`stage_id`/`iteration_id`). Every PM view is a **projection** of
that graph, and every projection shares the same three controls:

```
┌──────────────────────────────────────────────────────────────────────┐
│ ProjectHeader:  {queue name}  [Board] [Sprint] [Timeline] [Calendar] │
│                 [List]                    ViewSwitcher ▲             │
├──────────────────────────────────────────────────────────────────────┤
│ FilterBar: [+ filter] status:open assignee:@me priority:high         │
│ GroupBy (swimlanes): None ▾   SavedViews: "My open bugs" ▾  [Save]   │
├──────────────────────────────────────────────────────────────────────┤
│                    ...projection renders here...                     │
└──────────────────────────────────────────────────────────────────────┘
```

- **ViewSwitcher** — Board / Sprint / Timeline / Calendar / List tabs per queue. URL-addressable:
  `/app/[orgId]/items/boards/[boardId]/(board|sprint|timeline|calendar|list)`.
- **FilterBar** (comp 27, the most-reused component in the library) — token-based filters
  over status, type, priority, assignee, epic (parent), iteration, and any tri-scoped custom
  field. One implementation, all five views consume its output.
- **GroupBy = swimlanes.** Swimlanes are **not a new entity**; they are a client-side
  grouping over existing fields (assignee / epic / priority / item_type). This kills the
  proposed `board_swimlanes` table for v1 — zero schema cost, and it generalizes: GroupBy
  renders as swimlanes on Board, as row-groups on List/Timeline. A dedicated custom-lane
  entity can come later if field-based lanes prove insufficient.
- **SavedView** = named (FilterBar + GroupBy + view + sort) tuple. Personal by default,
  org-shareable. This is the one genuinely new backend concept (§4.3).

Elegance rules (per house style, theme-organic tokens only): restraint — cards carry at most
key · title · priority dot · assignee chip · estimate chip · due chip · epic tag · link
badge; everything else lives in detail. Optimistic updates with rollback (pattern already
established in board/page.tsx). Keyboard-first: `f` filter, `v` cycle views, `e` edit,
arrows+space to move cards. AI affordances are *ambient, not modal*: an "✨ suggest" button
per surface (triage inbox→board, plan sprint, groom backlog) that produces reviewable
proposals — matching US-008/023/028 where AI proposes and the human accepts.

---

## 3. Per-view design

### 3.1 Board (kanban) — upgrade in place
- Columns from `board_stages` (position-ordered) — unchanged.
- **DnD via `@dnd-kit`** (core+sortable): accessible (keyboard sensor), maintained, small.
  Card drop → optimistic `PATCH items/:id {stage_id, rank}`.
- **Within-column order via `items.rank`** (lexorank string, §4.1). Client computes midpoint
  rank between drop neighbors; server accepts as-is (rebalance job later if ranks saturate).
- WIP limits become *enforced-visible*: column count chip flips to `warning` token at limit,
  column header gets warning border; drops still allowed (soft limit) but toast explains.
- Swimlanes: GroupBy renders horizontal lanes with sticky lane headers (`SwimlaneHeader`
  comp 33); DnD works across lanes (sets the grouped field on drop, e.g. re-assign).
- Column config: gear menu per column → rename, WIP limit, reorder (exposes the already-
  implemented `update_stage` via new endpoints, §4.2). Board-create modal fixes the
  "create one via the API" dead end (items/page.tsx:54).
- Quick-add ghost card at column foot (title-only, inherits stage).

### 3.2 Sprint (scrum board + management) — new
- **Sprint selector** in ProjectHeader (from `board_iterations`; needs CRUD exposure §4.2).
  Sprint header strip: name · goal · date range · points committed/completed · days left ·
  `[Start sprint]` / `[Complete sprint]` (status transitions planned→active→completed;
  completing prompts to roll unfinished items to next sprint or backlog).
- Board area = same kanban component filtered to `iteration_id`.
- **Planning mode** (screen 14): split pane — ranked backlog left, sprint right; drag across
  to commit (sets `iteration_id`); running points tally vs. velocity hint. "✨ Plan sprint"
  proposes a cut-line per US-023.
- **Burndown** (`BurndownChart`, new comp): remaining points/count vs. ideal line. Requires
  status-transition history — sourced from `item_events` (§4.4). Velocity = completed points
  per past iteration, same source.
- Retro screen 17 unchanged (reads completed iteration).

### 3.3 Timeline (gantt) — new
- Rows = items grouped by epic (parent) or GroupBy field; collapsible groups.
- Bars span `start_date → due_date` (§4.1); items missing dates render in an "unscheduled"
  shelf, drag onto canvas to schedule. Drag/resize bar → PATCH dates.
- **Dependency arrows** from `item_links` `blocks/blocked_by` — draw only (no auto-shift in
  v1); violated dependency (successor starts before blocker ends) renders the arrow in
  `warning`. Critical path, auto-scheduling = explicitly out of scope v1.
- Zoom: week / month / quarter. Today line. Iteration bands shaded behind rows when the
  queue has iterations. Milestones deferred (no table; representable later as a dated
  zero-length item type).
- Cross-project rollup (US-031) deferred to a portfolio-level screen; this view is per-queue.

### 3.4 Calendar — new, cheap
- Month/week grid of items by `due_date` (real column after §4.1); drag between days to
  re-date. Personal time-blocking (US-017) stays a separate Today-side concern — this is the
  *team* calendar of due work. Renders the same ItemCard-mini as Board.

### 3.5 List / Backlog — upgrade in place
- `/items` splits: Boards list stays; "Backlog" becomes the **List view** of a queue —
  rank-ordered, DnD row reorder, virtualized (drop the `slice(0,40)` cap), sortable columns
  (rank default; due, priority, estimate, key), inline-edit estimate + priority.
- Grooming mode (screen 18): keyboard-driven walk of unestimated/stale items; "✨ groom"
  proposes estimates+splits per US-028, accept/reject per row.

### 3.6 Item detail — the connective tissue
Add (all backed by existing or §4.1 schema): due/start date pickers, estimate field,
iteration picker, parent/epic picker + children table with rollup (n of m done),
links section (blocks/blocked-by/relates, add/remove via existing endpoints),
**comments thread + activity feed** (trp_comments/ItemFeed — backend fully ready, biggest
missing daily-use feature), watch toggle, attachments. Editable item_type. Labels ride the
custom-fields system (multi_select), not a new table.

### 3.7 Epics as UX (no new entity)
`item_type: epic` + `parent_id` is sufficient. UX: epic tag chip on cards (color-hashed);
epic detail = item detail + children board/list + progress bar; GroupBy:epic gives epic
swimlanes and timeline groups. Spec needs a story making this first-class (§6).

---

## 4. Backend workplan (narrow, additive)

Migration IDs: pick from the roadmap's allocated block (`roadmap/README.md` migration-ID
allocation) — numbers below are placeholders. Schema is Liquibase-only (never Ecto-migrate).

### 4.1 Item columns (1 changelog)
`items.rank varchar` (lexorank, indexed `(queue_id, rank)`), `items.start_date date`,
`items.due_date date` (indexed `(organization_id, due_date)`), `items.estimate numeric`.
Backfill due_date/estimate from `custom_fields` convention (Today.due_soon already reads
it — switch Today to the real column after backfill). Expose all four in `ItemUpdate`
MCP tool + `PATCH /items/:id`.

### 4.2 Expose existing stage/iteration CRUD (0 schema)
Context functions `add/update/delete_stage`, `add/update/delete_iteration` already exist in
`Domains.Items.Queues` — add HTTP sub-resources
(`POST/PATCH/DELETE /queues/:id/stages/:stage_id`, same for `/iterations`) + MCP tools
(`StageCreate/Update/Delete`, `IterationCreate/Update/Delete`). Scrum default seeding gets
an initial iteration.

### 4.3 `saved_views` (1 changelog)
`saved_views(id, organization_id, project_id?, queue_id?, user_id, name, view, filters
jsonb, group_by, sort, is_shared bool)` + CRUD routes + MCP tools (agents benefit: "open my
review queue").

### 4.4 `item_events` (1 changelog)
`item_events(id, item_id, actor, field, old_value, new_value, occurred_at)` — written from
the item update changeset for status/stage/iteration/estimate/assignee transitions. Powers
burndown, velocity, activity feed, and future audit. (Verify first whether ItemFeed already
persists anything equivalent; if it does, extend rather than add.)

Explicitly **not** doing: workflow enforcement of `status_workflow` jsonb (render-as-hints
only for now), swimlane table, milestones table, critical-path math.

---

## 5. Frontend workplan

New deps: `@dnd-kit/core` + `@dnd-kit/sortable` only. Gantt and calendar are hand-rolled on
CSS grid + absolutely-positioned bars (SVG layer for dependency arrows) — no heavyweight
chart/gantt lib; keeps theme-token styling and bundle small. Burndown = existing sparkline
approach or tiny inline SVG.

New/changed components (extends the 76-component library; names per its conventions):
`ViewSwitcher`, `FilterBar` (build the long-specced comp 27), `SavedViewMenu`,
`SwimlaneHeader` (comp 33), `ItemCard` (unify board/calendar/backlog card),
`EstimateChip`+`EstimatePicker`, `DueDateChip`, `EpicTag`, `SprintHeader`,
`BurndownChart`, `GanttCanvas`+`GanttBar` (comp 12)+`DependencyArrow` (comp 8),
`CalendarGrid`, `CommentThread`, `ActivityFeed`, `ItemPicker` (parent/link selection).

**A hard prerequisite:** `layout.tsx` does `loadConfig()`/`loadAllBrandings()` filesystem
scans per request (cause of the 2026-07-22 prod 500; Dockerfile now ships `src/config`).
Before adding request-time-SSR'd PM views, hoist theme config to module scope / build-time
constant so these screens don't pay (or re-trip) that cost.

---

## 6. Spec-side work (stories/screens to add or amend)

New stories (next free id — corpus currently ends at US-101):
1. **Saved views** — save/name/share filter+group+sort per view (persona: Sarah, James).
2. **Manual estimation** — human story-point/estimate entry & inline edit (today only AI
   emits estimates; humans can't).
3. **Burndown & velocity** — sprint charts from event history.
4. **Swimlane grouping** — promote from "future enhancement" prose in US-022 to a committed
   story (field-based GroupBy).
5. **Epic management** — epic as first-class UX (create, children rollup, epic views).
6. **Team due-date calendar** — distinct from US-017 personal time-blocking.
7. **Item collaboration surface** — comments/activity/watch in item detail (backend exists;
   no story claims the UI).

Housekeeping flagged by audit, needs an owner decision: reconcile screen count (README "55"
vs roadmap "74/76"); Diana (freelancer/billing) persona has zero story coverage; stale
`projects/tobarnalp.com` typo-duplicate dir; roadmap Flag 4 gates implementation on a PRD
pass — the phases below assume PRDs get written for the stories they contain.

---

## 7. Phasing (each phase ships something visibly better)

| Phase | Contents | Backend dep |
|---|---|---|
| **A — Board feels real** | @dnd-kit board DnD, rank ordering, FilterBar, board-create + column config UI, ItemCard v2 (chips), item-detail fields (dates/estimate/iteration/parent), comments+activity in detail | §4.1, §4.2, (§4.4 for activity) |
| **B — Scrum** | Sprint selector + header, planning split-pane, start/complete flows, burndown/velocity, grooming mode on List | §4.2, §4.4 |
| **C — Time** | Timeline/gantt view (bars, dependency arrows, drag-reschedule), Calendar view | §4.1 (done in A) |
| **D — Views & lanes** | SavedViews end-to-end, GroupBy/swimlanes across Board+List+Timeline, keyboard layer, AI suggest buttons wired (triage/plan/groom) | §4.3 |

Sequencing rationale: A touches every later view (card, filter, rank, detail); B before C
because sprints exercise §4.2/§4.4 while gantt only needs dates; D last because saved views
are only valuable once there are views worth saving.

---

*Audit sources: stories/frontend/backend scout reports, session 2026-07-22. Supersedes
nothing; complements `IMPLEMENTATION-SEQUENCE.md` (component tiers) and `roadmap/`.*
