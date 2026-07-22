---
id: US-021
title: "Create a project with a chosen methodology → provisioned board"
workstream: WS-C
lane_owner: WS-C (backend domains/projects + frontend app/[orgId]/projects/** + components/pm/**)
personas: [sarah-kim]
domain: projects
priority: high
mvp_phase: "v0.1"
migration_block: "logical 110–114 → physical changelog 035 (see §3)"
status: draft
depends_on: [026-items-queues, 017-projects, Authz-PBAC]
references: [US-022, US-023, US-027, US-028]
---

# US-021 — Project Creation with Methodology Provisioning

## 1. Overview

### Summary
Turn project creation from a thin entity insert into a **one-shot provisioning
flow**: the creator picks a delivery methodology (Kanban, Scrum, Waterfall, or
Custom) and the platform atomically stands up the project **and** its default
board — the methodology's stage set (+ an initial active iteration for Scrum) —
so the team's workflow is usable from the first click.

The board/stage/iteration machinery **already exists** (`Domains.Items.Queues`,
`item_queues`, `board_stages`, `board_iterations`, `default_stages/1`,
methodology-aware seeding). Projects today (`Therobotplans.Projects`,
`schema/projects/project.ex`, changelog 017) are a thin org→project entity with
no methodology and no board linkage. **This story is the orchestration seam**:
project ⟶ default board provisioning + linkage, exposed over REST + MCP + a
create-project wizard UI. We do not rebuild queues/stages — we compose them.

### Persona / JTBD
- **Sarah Kim, Small-Team Eng Lead.** Sets up a delivery project for her team.
- **Job:** "When I start a new project, I want to declare how my team works
  (Scrum/Kanban/Waterfall/Custom) once, and get a ready-to-use board seeded to
  that method, so nobody hand-builds columns and the workflow matches the work
  from day one."
- Methodology selection must feel like a **lightweight choice, not a ceremony**:
  a preview of what each option provisions, and an easy path to switch later.

### Goal / non-goal boundary
| In scope (this story) | Out of scope (referenced) |
| :-- | :-- |
| Project create w/ methodology + atomic board provisioning + linkage | Kanban DnD board UI → **US-022 / Chunk E** |
| Methodology preview, project list, project→board deep link | AI sprint planning → **US-023 / US-027** |
| Edit/archive/unarchive (extend existing project routes) | AI backlog grooming → **US-028** |
| Idempotent re-provision; PBAC gating | Cross-project item migration engine on methodology *change* (stub only, §2.7) |

---

## 2. Functional Requirements

### 2.1 Project creation with methodology (expanded AC-1, AC-2)
- The create surface accepts, in addition to today's `name`, `slug`,
  `description`, `settings`: a **required `methodology`** ∈
  `{kanban, scrum, waterfall, custom}` and an optional **`key_prefix`**
  (reuse existing column, §3.1; auto-derived from slug if omitted).
- `custom` is accepted at the API/DB layer but provisions the **kanban default
  stage set** as a starting point (the user then edits stages via existing
  `POST /queues/:id` stage endpoints — the "escape hatch"). No bespoke
  custom-template store in MVP (§3.3, open question OQ-2).
- On success the project is created **and** a default board is provisioned in a
  single transaction (§4). Partial state is impossible: either both exist and
  are linked, or neither does.

### 2.2 Methodology provisioning (AC-2)
On provisioning, map methodology → seeded artifacts via the **existing**
`Domains.Items.Queues.default_stages/1`:

| Methodology | Seeded stages (`board_stages`, kind) | Iteration seeded |
| :-- | :-- | :-- |
| `kanban` | To Do·todo → In Progress·in_progress → Done·done | none |
| `scrum` | To Do → In Progress → In Review → Done | **1 active** "Sprint 1" (`board_iterations`, status=active, sequence=0) |
| `waterfall` | Requirements → Design → Implementation → Verification → Maintenance (kind=phase) | none |
| `custom` | falls through to kanban default set (editable) | none |
| `spiral` | Planning → Risk Analysis → Engineering → Evaluation | none (supported by engine; not offered in wizard — OQ-3) |

- WIP limits: kanban columns are seeded with `wip_limit = null` (unlimited);
  configurable later via stage update (US-022 renders them).
- The board's `methodology` mirrors the project's `default_methodology`.
- **Scrum-only rule:** exactly one iteration seeded, `status = "active"`, named
  "Sprint 1". This is the additive behavior beyond today's `Queues.create/1`
  (which seeds stages but **not** iterations) — implemented in the provisioning
  service, not by changing `Queues.create/1`.

### 2.3 Project → default board linkage (AC-4 display)
- `projects.default_queue_id` (§3.1) FK → the provisioned board.
- `GET /projects/:id` returns `default_methodology` + `default_queue{ id, slug,
  methodology, stage_count }` so the dashboard shows the methodology and can
  deep-link to the board.

### 2.4 Empty state (AC — project list)
- Org with zero projects renders an `EmptyState` (existing `@/components/ui`)
  with a primary "Create project" CTA that opens the wizard.

### 2.5 Edit / archive (extend existing routes)
- `name`, `description`, `slug`, `key_prefix`, `settings` are editable via the
  existing `PATCH .../projects/:id`. **`default_methodology` is NOT editable
  in-place** for MVP (mirrors `item_queues.methodology` immutability — stages
  depend on it). Changing methodology = §2.7 re-provision flow.
- Archive/unarchive reuse existing `POST .../projects/:id/archive|unarchive`.
  Archiving a project does **not** delete its board (board rows persist; hidden
  from active lists by project status).

### 2.6 Permissions (AC — all)
- Create gated by PBAC `project:create` on the **organization** (as today).
- Provisioning runs under the creator's authority in the same request — no
  separate board permission check; board is an implementation detail of the
  project the caller is authorized to create.
- View/edit/archive gated by `project:view` / `project:update` / `project:archive`
  on the **project** (as today). Cross-project isolation enforced by PBAC
  (acceptance test §7.4).

### 2.7 Methodology change later (AC-4, partial — stub)
- **In scope:** endpoint contract + provisioning idempotency that supports
  re-provision. `POST .../projects/:id/provision` with `{methodology}`:
  - If project already has `default_queue_id` and the requested methodology
    equals the current → **no-op**, returns existing board (idempotent).
  - If different → provisions a **new** board (new slug `board-<methodology>`),
    repoints `default_queue_id`, leaves the old board intact.
- **Out of scope (deferred, OQ-1):** migrating in-flight items' `stage_id`
  from the old board's stages to the new board's stages, and the UI "migration
  prompt." MVP repoints the default board; item re-mapping is US-022-adjacent
  follow-up. The endpoint returns `migration_required: true` + a stage-mapping
  hint payload so the frontend can later drive the prompt.

### 2.8 Scale-free items unaffected (AC-5)
- No change to item types. Todos/tasks/bugs/epics remain available regardless of
  methodology (they already are — items reference `queue_id`/`stage_id`
  optionally). This story only governs board/cadence provisioning. **Verify**
  (test §7.6) that item creation in a provisioned project works with and without
  a stage assignment.

---

## 3. Data Model — Liquibase changelog 035 (logical block 110–114)

> **Numbering reconciliation.** The roadmap lane names block **110–114**
> (110 `projects`, 111 `workflow_states`). Physically, changelogs are sequential
> and the last applied is `034-item-rank-dates-events.yaml`; the next file is
> **`035-project-methodology.yaml`**. The logical 110/112 "projects" work maps
> to the ALTER below. **Logical 111 `workflow_states` is intentionally NOT
> created** — see §3.3.

### 3.1 `projects` — additive ALTER (logical 110/112)
`projects` already has (changelog 017 + 028a): `id, organization_id, name, slug,
description, settings jsonb, status, key_prefix, created_by, archived_at,
timestamps`; unique `(org, slug)` and `(org, key_prefix)`.

Add two columns:

```yaml
# db/changelog/035-project-methodology.yaml
databaseChangeLog:
  - changeSet:
      id: 035-projects-add-methodology
      author: therobotplans
      changes:
        - sql:
            sql: |
              ALTER TABLE projects
                ADD COLUMN default_methodology varchar(255) NOT NULL DEFAULT 'kanban'
                  CHECK (default_methodology IN ('kanban','scrum','waterfall','spiral','custom')),
                ADD COLUMN default_queue_id uuid
                  REFERENCES item_queues(id) ON DELETE SET NULL;
              CREATE INDEX idx_projects_default_queue_id
                ON projects (default_queue_id);
      rollback:
        - sql:
            sql: |
              DROP INDEX IF EXISTS idx_projects_default_queue_id;
              ALTER TABLE projects
                DROP COLUMN IF EXISTS default_queue_id,
                DROP COLUMN IF EXISTS default_methodology;
```

- **`default_methodology`** — queryable, CHECK-constrained (superset of the
  board's four; adds `custom`). Not stored only in `settings` jsonb because it
  drives provisioning and dashboards and benefits from a constraint.
- **`default_queue_id`** — nullable FK (`ON DELETE SET NULL` so deleting a board
  never orphan-blocks a project); the linkage from §2.3.
- **`key`** — the ticket's "key" is the **existing `key_prefix`** column
  (2–16 uppercase alnum, unique per org). No new column; the wizard writes
  `key_prefix`.

Register in `db.changelog-master.yaml` after `034`.

### 3.2 Reused tables (no change)
- `item_queues` (026): the board; already has `methodology`, tri-scope,
  per-project uniqueness.
- `board_stages` (026): **this IS the workflow-states store** — ordered, named,
  `kind`, `position`, `wip_limit`, per-board arbitrary stages.
- `board_iterations` (026): sprints/cycles; provisioning seeds one for scrum.

### 3.3 Decision — reuse `board_stages`, do NOT create `workflow_states` (logical 111)
**Call: reuse.** Justification:
1. `board_stages` already models exactly "an ordered, named workflow state with
   a kind and a WIP limit, scoped to a board." A parallel `workflow_states`
   table would duplicate it and force a join/sync no consumer needs.
2. The methodology **templates** live in code as `Queues.@default_stages` /
   `default_stages/1` — a pure, versioned source of truth. Seeding materializes
   a template into `board_stages` rows per board. Templates don't need DB
   persistence because they're constant and identical across projects.
3. "Custom methodology = arbitrary states" is satisfied by editing a board's
   `board_stages` directly (existing stage CRUD) — no schema addition.
4. A separate `workflow_states`/`methodology_templates` table is justified
   **only if** an org must define a *reusable named custom template once and
   apply it to many future projects*. That is not in US-021's AC. Deferred as
   **OQ-2**; if it lands, add `methodology_templates(org_id, slug, stages jsonb)`
   as a later changelog and have `provision/3` read it when
   `methodology == "custom"`.

---

## 4. Provisioning Service

### 4.1 Placement
Extend the existing **`Therobotplans.Projects`** context (not a new
`Domains.Projects` — the project context already lives at
`lib/therobotplans/entities/projects.ex`). Orchestrate the existing
`Domains.Items.Queues` from there. Rationale: keep one project context; Queues
stays the board authority.

### 4.2 Public API
```elixir
@type methodology :: String.t()  # "kanban"|"scrum"|"waterfall"|"spiral"|"custom"

@doc """
Create a project with an owner AND provision its default board (stages +
scrum iteration) atomically. Returns the project with default_queue_id set.
"""
@spec create_with_methodology(map(), methodology(), Ecto.UUID.t(), Noizu.Context.t()) ::
        {:ok, %{project: Schema.t(), board: ItemQueue.t()}} | {:error, term()}
def create_with_methodology(attrs, methodology, user_id, context \\ Noizu.Context.system())

@doc """
Idempotently provision (or re-provision) a project's default board for a
methodology. If the project's default board already matches, returns it
unchanged. If it differs, provisions a new board and repoints default_queue_id.
"""
@spec provision(Schema.t() | Ecto.UUID.t(), methodology(), keyword()) ::
        {:ok, %{board: ItemQueue.t(), migration_required: boolean(), stage_map: map()}}
        | {:error, term()}
def provision(project, methodology, opts \\ [])
```

### 4.3 Transaction / rollback behavior
`create_with_methodology/4` wraps everything in a single
`Therobotplans.Repo.transaction/1`:

1. Insert `projects` row (`Schema.changeset`, incl. `default_methodology =`
   normalized methodology, `created_by = user_id`).
2. Add owner membership (`Authz.ScopedMemberships.add_member("project", id,
   user_id, "owner")`) — same as today's `create_with_owner/3`.
3. **Provision board** = call the board-seed logic. Because
   `Queues.create/1` itself opens a `Repo.transaction`, calling it here **joins
   the parent transaction** (Ecto nests via savepoint) — a rollback anywhere
   aborts the whole unit. Provisioning steps:
   - Insert `item_queues` (`name: "#{project.name} Board"`, `slug: "board"`,
     `organization_id`, `project_id: project.id`, `methodology:` the four-value
     board methodology, mapping `"custom" → "kanban"`).
   - Seed `board_stages` from `Queues.default_stages(board_methodology)` with
     `position` = index (existing behavior).
   - If `methodology == "scrum"`: insert one `board_iterations` row
     (`name: "Sprint 1"`, `sequence: 0`, `status: "active"`).
4. `UPDATE projects SET default_queue_id = board.id`.
5. Return `%{project: reloaded_project, board: get_board(board.id)}`.

Any `{:error, changeset}` → `Repo.rollback(changeset)` → caller gets
`{:error, changeset}`; **no orphan project, no orphan board.**

### 4.4 Idempotency (`provision/3`)
- Load project; if `default_queue_id` set:
  - fetch board; if `board.methodology == normalize(methodology)` →
    return `{:ok, %{board: board, migration_required: false, stage_map: %{}}}`
    (no writes) — **idempotent**.
  - else provision a new board (slug `"board-#{methodology}"`), repoint
    `default_queue_id`, compute `stage_map` (old.slug → new.slug best-effort by
    matching `slug`/`kind`), return `migration_required: true`.
- Concurrency: rely on the per-scope unique board slug index
  (`idx_item_queues_project_slug`) to prevent duplicate default boards under a
  race — second inserter hits a unique violation and the transaction retries or
  returns the existing board.

---

## 5. API Surface

All under existing `scope "/api/v1/organizations/:org_id"`,
`pipe_through [:api, :authenticated]`, `TherobotplansWeb.ProjectController`.

### 5.1 `POST /organizations/:org_id/projects` (extend)
- **Extend** the existing `create/2` to read `project["methodology"]`
  (default `"kanban"`) and `project["key_prefix"]`, and call
  `Projects.create_with_methodology/4` instead of `create_with_owner/3`.
- Gate unchanged: `Authz.check_permission(user_id, "organization", org_id,
  "project:create")` → 403 otherwise.
- Request:
  ```json
  { "project": { "name": "Apollo", "slug": "apollo", "methodology": "scrum",
                 "key_prefix": "APL", "description": "..." } }
  ```
- 201 response includes the provisioned board ref:
  ```json
  { "project": { "id": "...", "name": "Apollo", "slug": "apollo",
                 "default_methodology": "scrum", "key_prefix": "APL",
                 "default_queue": { "id": "...", "slug": "board",
                                    "methodology": "scrum", "stage_count": 4 } } }
  ```
- 422 on invalid methodology (changeset error) / duplicate slug / bad key_prefix.

### 5.2 `GET /organizations/:org_id/projects/:id` (extend `show/2`)
- Gate `project:view` (unchanged). Extend `project_to_json/1` to include
  `default_methodology` and a `default_queue` sub-object (id, slug, methodology,
  stage_count) by loading `Queues.get_board(project.default_queue_id)` when set.

### 5.3 `POST /organizations/:org_id/projects/:project_id/provision` (new)
- New route in the existing `scope "/projects/:project_id"` block (next to
  archive/unarchive).
- Gate `project:update`.
- Body `{ "methodology": "scrum" }` → calls `Projects.provision/3`.
- 200 `{ "default_queue": {...}, "migration_required": bool, "stage_map": {...} }`.

### 5.4 `GET /organizations/:org_id/projects` (unchanged shape, add field)
- Existing `index/2` (`list_for_user` via `list_user_accessible_projects` SQL
  fn). Include `default_methodology` in the row projection if the SQL function
  is updated; otherwise the list page lazy-loads methodology from `show`.
  **Recommendation:** add `default_methodology`, `default_queue_id` to the
  `list_user_accessible_projects` SELECT (SQL fn lives in changelog 019 /
  pbac-stored-procedures; a small follow-up changeset updates it). Flag as a
  minor dependency, not a blocker (§8).

### 5.5 MCP tools (idiomatic — extend)
- `Therobotplans.MCP.Projects.Tools.ProjectCreate` (`Project.Create`): add
  `field :methodology, :string, description: "kanban|scrum|waterfall|custom"`
  (default kanban) and route through `create_with_methodology/4`. Return the
  `default_queue` id in the result map. Mirrors the REST extension so agents
  provision boards the same way humans do (consistent with WS-J agent runtime).
- `Project.Get` returns `default_methodology` + `default_queue_id`.
- No new MCP tool needed for provisioning in MVP; re-provision is a human wizard
  action.

---

## 6. Frontend — `app/app/[orgId]/projects/**` + `components/pm/**`

> Today there is **no** `projects/` route and **no** project methods in
> `lib/api.ts` (only `listQueues/getQueue/createQueue`). Board rendering already
> exists at `app/[orgId]/items/boards/[boardId]` (stages + optimistic move — the
> deep-link target). Reuse it; do not rebuild.

### 6.1 API client additions (`lib/api.ts`)
Add to the `api` object + types:
```ts
export interface Project {
  id: string; name: string; slug: string; description?: string;
  default_methodology?: string; key_prefix?: string; status?: string;
  default_queue?: { id: string; slug: string; methodology: string; stage_count: number };
}
listProjects(orgId): Promise<{ projects: Project[] }>
createProject(orgId, data: { name; slug; methodology; key_prefix?; description? }): Promise<{ project: Project }>
getProject(orgId, id): Promise<{ project: Project }>
updateProject(orgId, id, data): Promise<{ project: Project }>
archiveProject(orgId, id) / unarchiveProject(orgId, id)
provisionProject(orgId, id, methodology): Promise<{ default_queue; migration_required; stage_map }>
```

### 6.2 Routes / screens
| Path | Screen | Notes |
| :-- | :-- | :-- |
| `app/[orgId]/projects/page.tsx` | **Project list** | `useApi(() => api.listProjects(orgId))`; cards show name, `default_methodology` badge, key_prefix, link to board. `EmptyState` when none (§2.4). "New project" opens wizard. |
| `app/[orgId]/projects/new/page.tsx` | **Create wizard** | 3 steps in a `Dialog` or stepped page (§6.3). |
| `app/[orgId]/projects/[projectId]/page.tsx` | **Project detail** | shows methodology, key_prefix, archive control, and a prominent **"Open board" deep link** → `app/[orgId]/items/boards/${default_queue.id}`. |

### 6.3 Create-project wizard (AC-1, AC-2 preview)
Reuse `@/components/ui` (`Dialog, Input, Select, Button, FieldLabel,
SectionCard, EmptyState`) + `useMutation`.
1. **Step 1 — Details:** `name` (Input), `slug` (auto-slug from name, editable),
   optional `key_prefix` (auto-derive uppercase from slug), `description`.
2. **Step 2 — Methodology picker:** four selectable cards (Kanban / Scrum /
   Waterfall / Custom). Selecting one renders a **board preview** — the column
   list it will provision, sourced from a small **client-side constant** that
   mirrors `Queues.default_stages/1` (kanban 3, scrum 4 + "Sprint 1", waterfall
   5 phases, custom = kanban starter, editable later). Preview copy notes Scrum
   seeds an active sprint. Keep it a lightweight choice per the story's tone.
3. **Step 3 — Confirm:** summary → `api.createProject`. On success, toast +
   route to `app/[orgId]/projects/${id}` (or straight to the board).
- New `components/pm/methodology-picker.tsx` (the card selector + preview) and
  `components/pm/methodology-badge.tsx` (list/detail badge). Dark-mode via the
  existing token styles (Maya lives in dark mode — US-022 note).

### 6.4 Navigation
Add "Projects" to `components/pm/org-nav.tsx`.

---

## 7. Acceptance Tests

Backend (`test/therobotplans/projects_test.exs` + controller test):
1. **Provisioning idempotency:** `provision/3` twice with same methodology →
   one board, same `default_queue_id`, no duplicate stages. Second call performs
   no writes.
2. **Per-methodology stage seeding:** create project with each of
   kanban/scrum/waterfall/custom → assert exact stage slugs/order match
   `Queues.default_stages/1` (custom == kanban set).
3. **Scrum iteration:** scrum project → exactly one `board_iterations` row,
   `status == "active"`, `name == "Sprint 1"`; kanban/waterfall → zero.
4. **PBAC cross-project denial:** user without `project:view` on project B gets
   403 from `GET .../projects/B`; a member of A cannot provision B's board.
5. **Atomic rollback:** force a board-seed failure (e.g. invalid methodology
   injected past the changeset) → assert **no** `projects` row persisted
   (transaction rolled back).
6. **Board-link resolves + scale-free items:** `GET /projects/:id` returns a
   `default_queue.id` that `GET /queues/:id` resolves; create an item in the
   project with and without `stage_id` → both succeed.
7. **Create-time gate:** caller lacking org `project:create` → 201 never issued;
   403 returned; no rows written.
8. **Re-provision switch:** project on kanban, `provision(scrum)` → new board,
   `default_queue_id` repointed, old board still fetchable,
   `migration_required == true`.

Frontend (component/e2e, thin): wizard requires methodology before confirm;
preview matches selected methodology; project list empty-state renders CTA;
detail "Open board" navigates to `boards/[default_queue.id]`.

---

## 8. Dependencies, Out-of-Scope, Open Questions

### Dependencies (existing, reused — not built here)
- `Domains.Items.Queues` + `default_stages/1` (board/stage/iteration engine).
- `item_queues` / `board_stages` / `board_iterations` (changelog 026).
- `Therobotplans.Authz` PBAC (`check_permission/4`, `project:create|view|update|
  archive`), `Authz.ScopedMemberships.add_member/4` (owner grant).
- Existing `ProjectController`, `QueueController`, board UI at
  `items/boards/[boardId]`, `@/components/ui`, `useApi`/`useMutation`.
- **Minor upstream tweak:** `list_user_accessible_projects` SQL fn to surface
  `default_methodology`/`default_queue_id` in the list (§5.4) — small changeset,
  not a blocker.

### Out of scope (reference, do not build)
- Kanban drag-and-drop board interactions → **US-022 (Chunk E)** — board render
  target already exists; we only deep-link to it.
- AI sprint planning / retro / backlog grooming → **US-023 / US-027 / US-028**.
- Full item-migration engine + UI migration prompt on methodology change
  (§2.7 ships the endpoint + `stage_map` hint only).
- Org-reusable named custom methodology templates (see OQ-2).

### Open questions
- **OQ-1 (methodology change migration):** On re-provision, how are in-flight
  items re-mapped old-board→new-board stages — auto by `stage_map`, or
  user-confirmed prompt (AC-4)? MVP defers item re-mapping; endpoint returns the
  hint. Decide UX with US-022.
- **OQ-2 (custom templates):** Is a persisted, org-reusable custom methodology
  template required, or is per-board stage editing sufficient? PRD assumes the
  latter; a `methodology_templates` table + `provision` read-path is the
  additive path if not (§3.3).
- **OQ-3 (spiral in wizard):** engine supports `spiral`; wizard offers only the
  four AC methodologies. Expose spiral as an advanced option, or keep engine-only?
- **OQ-4 (default board slug/name):** confirm `slug: "board"`,
  `name: "<Project> Board"` conventions; and whether a project may have multiple
  boards at GA (schema already allows N boards per project; `default_queue_id`
  just names the primary).
