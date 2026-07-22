---
title: "ADR-001: Items as the Polymorphic Work Primitive"
lane: WS-L (Platform Shell & Cross-Domain)
milestone: M0 (Baseline Audit & Platform Contracts)
status: accepted (ratifies live implementation)
grounded_against: app/backend commit on branch feat/ex-litellm; changelogs 001–034
supersedes: none
affects: WS-A, WS-C, WS-D, WS-I (all consume items as their base entity)
---

# ADR-001: Items as the Polymorphic Work Primitive

## Status

**Accepted.** This ADR ratifies an architecture that is **already live in production code**
(`Therobotplans.Schema.Item`, `Domains.Items`, changelogs through `034`). It documents and
freezes a decision the codebase has already made, so that the ~six lanes building on items
(personal todos, project delivery, bugs, OKRs) extend the one primitive rather than
re-deriving a competing one.

## Context

`therobotplans` tracks many kinds of work: personal todos, project tasks, bugs, epics,
stories, and — by extension — anything with a title, an owner, a status, and a lifecycle.
The naive schema is a table per type (`todos`, `tasks`, `bugs`, `epics`, …), each with 80%
overlapping columns and its own CRUD, its own board query, its own audit trail, its own
human-key scheme. That path multiplies every cross-cutting feature (comments, links,
watches, custom fields, notifications, KR-backing, Today aggregation) by the number of
types and guarantees drift.

The backend instead already implements a **single `items` table** with a discriminator
column and behaviour-extension by convention. This ADR ratifies that model and draws the
scope line for M1.

### What is already built (grounded)

`Schema.Item` (`schema/item.ex`) — one table, these columns:

| Column | Role |
|---|---|
| `id` (uuid) | primary key |
| `organization_id` (uuid, required) | tenant scope; items are **org-required, project-optional** |
| `project_id` (uuid, nullable) | optional project scope |
| `item_type` (string, required) | **the discriminator** — `todo` / `task` / `bug` / `epic` / `story` / … |
| `title`, `description` | content |
| `status` (string, default `open`) | lifecycle state; terminal set `done`/`closed` (used by Today + KR completion) |
| `priority` (string) | `low`/`medium`/`high`/`critical` (validated) |
| `assignee`, `reporter` (string user ids) | ownership |
| `parent_id` (uuid → items) | self-reference — **hierarchy without a new entity** (epic→story→task) |
| `queue_id`, `stage_id`, `iteration_id` | board / kanban / sprint placement |
| `rank` (lexorank string) | board ordering (ch034) — index `(stage_id, rank)` |
| `start_date`, `due_date` (date) | scheduling (ch034) — index `(organization_id, due_date)` |
| `estimate` (numeric) | sizing (ch034) |
| `custom_fields` (jsonb, default `{}`) | tri-scoped typed extension bag (see below) |
| `number` (int) + `key` (string) | immutable human key `PREFIX-NNN`, race-safe per (org) or (org,project) |

Behaviour already hanging off the one primitive (no per-type duplication):
- **Human keys** — `Domains.Items.create/1` assigns `PREFIX-NNN` via an atomic per-scope
  counter (`item_number_counters`), gap-free, race-safe, backfillable. One generator for
  every `item_type`.
- **Item ↔ item links** — `item_links` (typed edges: blocks, relates, duplicates, …) via
  `link/3` / `get_links/1`. One link table for all types.
- **Item ↔ entity links** — `item_entity_link` bridges an item to any other domain entity.
- **Tri-scoped custom fields + type definitions** — `Domains.Items.Definitions`:
  `item_field_definition` / `item_type_definition` / `item_type_field`, resolved with
  **project > org > global** precedence and `disabled` tombstones. A "type" (e.g. `bug`) is
  a *definition row with a field set and a status workflow*, not a table.
- **Append-only history** — `item_events` (ch034): one row per changed tracked field
  (`status`, `stage_id`, `iteration_id`, `estimate`, `assignee`, `priority`), written
  best-effort on every `update/3` **outside** the write txn (a failed event insert never
  rolls back the item). Indexed `(item_id, occurred_at)` and `(item_id, field)`. This is
  the substrate for history views and burndown.
- **KR-backing** — `kr_item_links` connect items to OKR key results; completing an item
  drives `auto_progress` KR recompute. OKRs measure items; they don't re-model work.
- **Notifications fan-out** — `update/3` best-effort dispatches `:item_assigned` /
  `:item_update` through `Notifications.Dispatch`, guarded.
- **Today** — the unified plan reads items by `assignee` + status + `due_date`. One query
  shape covers every type.
- **MCP + REST** — one `item_*` tool family (`item_create/get/update/list/link/watch/
  comment/attach/feed`) and one `ItemController` (`resources "/items"`, `:id` accepts UUID
  **or** human key) serve all types.

## Decision

**Items are the single polymorphic work primitive. Every kind of trackable work is a row in
`items`, discriminated by `item_type`, extended by real columns for universal concerns and
by tri-scoped `custom_fields` / type-definitions for type-specific concerns.** All
cross-cutting behaviour (keys, links, events, watches, comments, attachments, KR-backing,
notifications, Today) is implemented **once against `items`** and inherited by every type.

Concretely, and normatively for the lanes:

1. **New work types are `item_type` values, not new tables.** WS-A todos/habit-instances,
   WS-C tasks/stories, WS-D bugs are all `items` with distinct `item_type`. A lane adds its
   type by seeding an `item_type_definition` (fields + status workflow), not a migration for
   a new table.
2. **Epics are `item_type: "epic"` + `parent_id`, not a separate entity.** Hierarchy
   (epic → story → sub-task) is the self-referential `parent_id`. There is **no `epics`
   table and will be none.**
3. **Universal, queryable-hot attributes ride real columns.** `status`, `priority`,
   `assignee`, `rank`, `start_date`, `due_date`, `estimate`, board placement — promoted to
   columns because Today/board/burndown queries filter and sort on them (indexes exist).
   ch034 promoted `due_date`/`estimate` **out of** `custom_fields` into columns precisely
   because the read paths needed them indexed.
4. **Type-specific or sparse attributes ride `custom_fields` by convention, typed by
   definitions.** A bug's `severity`, `steps_to_reproduce`; a story's `acceptance_criteria`
   — declared as `item_field_definition`s at global/org/project scope, stored in the jsonb
   bag, validated by convention (definition-driven), not by a column per type.
5. **History/burndown come from `item_events`, not per-type audit tables.** Any type-level
   history, activity feed, or burndown reads the one append-only log.
6. **Human identity is `PREFIX-NNN` for every type**, from the one generator. A bug and a
   task in the same project draw from the same per-project counter — keys are unique per
   org across the org bucket and every project bucket.

## Consequences

### Positive
- **Cross-cutting features are written once.** Comments, links, watches, attachments,
  events, KR-backing, notifications, and Today already work for *every* type because they
  target `items`. A new type inherits all of it for free.
- **Zero-migration new types.** Adding "incident-task" or "chore" is a definition seed +ish,
  not schema work — enables lanes to move without WS-L migration coordination.
- **One board/Today/search query shape.** Filtering, ranking (the `critical>high>medium>low`
  CASE), due-soon, and full-text all operate on one table with one index set.
- **Uniform human keys and deep links** across the product — `PROJ-123` means the same
  lookup regardless of type.

### Negative / accepted trade-offs
- **`item_type` is a string, not an FK-enforced enum.** Validity of a type is enforced by
  convention + definitions, not a DB constraint. Accepted: the tri-scoped definition system
  is the source of truth for "what types exist here," and a hard enum would defeat
  zero-migration extensibility. Lanes MUST create the `item_type_definition` before minting
  items of that type.
- **`custom_fields` is jsonb — no column-level typing at rest.** Type safety for
  type-specific fields lives in the definition layer + changeset conventions, not the DB.
  Accepted; the ch034 precedent shows the escape hatch: promote a field to a real column
  when a read path needs to index it.
- **Wide-ish table.** One table carries columns not every type uses (`estimate` on a
  personal todo). Accepted — nullable columns are cheap; the alternative (per-type tables)
  is far more expensive in code and joins.
- **Polymorphism is unconstrained by the DB.** Guardrails (which statuses a type allows,
  which fields are required) live in `item_type_definition.status_workflow` +
  `item_type_field.required`, enforced in the domain/changeset layer. Lanes MUST route type
  rules through definitions, not ad-hoc validation.

### Explicitly rejected alternatives
- **Table-per-type** (`todos`, `tasks`, `bugs`, `epics`). Rejected: multiplies every
  cross-cutting feature by N and guarantees drift.
- **A separate `epics` entity.** Rejected: hierarchy is `parent_id`; an epic is an item.
- **STI with a column per possible field.** Rejected: `custom_fields` + definitions gives
  sparse extension without schema churn.
- **A generic EAV table for all attributes.** Rejected in both directions: hot attributes
  are columns (indexable); sparse ones are jsonb (one bag, definition-typed). No separate
  attribute-value table.

## Scope for M1 (the ch034 baseline)

**In scope (live, build directly on):**
- `items` table with the full column set above, incl. ch034 `rank`/`start_date`/`due_date`/
  `estimate`.
- `item_events` append-only log (write path live; read/history/burndown views land per-lane
  in M2–M3).
- Tri-scoped `Definitions` (fields, types, type-fields; project>org>global; tombstones).
- Human-key generation + backfill; item↔item and item↔entity links.
- KR-backing (`kr_item_links`, auto-progress).
- One REST + one MCP surface for CRUD, links, comments, attach, feed, watch.

**Deferred (out of M1, do not block on):**
- **Per-type status workflows enforced at write time** — `status_workflow` is stored on the
  type definition; enforcement (rejecting illegal transitions) is a lane feature (e.g. WS-D
  bug SLA states, WS-E deploy states) in M2+.
- **Burndown / velocity / activity-feed reads** over `item_events` — M2–M3 per lane.
- **Full-text / pgvector search** over items (duplicate detection US-037, KB search) —
  M3, additive.
- **Recurrence** (habits US-012) — modeled as items + a recurrence rule in WS-A, not a
  schema change here.
- **Time tracking / billing** (Diana Kovacs gap, roadmap Flag 5) — no item columns; will be
  linked entities when scheduled.

## Normative rule for lanes

> If your lane tracks a unit of work with a title, an owner, and a status, it is an `item`
> with your `item_type`. Do not create a parallel table. Add type-specific fields as
> `item_field_definition`s; promote one to a column only via a WS-L interface ticket when a
> read path must index it. Get history from `item_events`. Get identity from the key
> generator. Build your type's rules into its `item_type_definition`.
