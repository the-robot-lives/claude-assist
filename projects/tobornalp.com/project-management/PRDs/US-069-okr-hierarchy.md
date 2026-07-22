---
id: US-069
title: "Multi-level OKR hierarchy with roll-up"
workstream: WS-I
milestone: M1
size: L
personas: [sarah-kim]
domain: goals
app: therobotplans
status: draft
migration_block: 140-144
depends_on: [okr-controller-authz-template, goals-recompute-progress, items-status-hook]
---

# PRD — US-069: Multi-level OKR hierarchy with progress roll-up

## 1. Overview

Objectives in `:therobotplans` already carry a self-referential `parent_id`, but the
domain treats the OKR graph as flat: `Goals.objective_progress/1` aggregates only an
objective's own Key Results and ignores its `children`. US-069 turns the existing
substrate into a true multi-level hierarchy — company → team → individual — where a
parent objective's progress is a rollup of its child objectives **and** its own KRs,
recomputed automatically as work lands. It also closes the REST/UI CRUD gaps that block
day-to-day OKR management (edit/delete KRs, check-ins, item links, child objectives).

This is the **M1 foundation** the M3 WS-I merged US-013/US-074 personal-OKR **visibility
layer** builds on (Roadmap Flag 1). It is the hierarchy; visibility scoping is out of scope.

**Substrate (EXTEND, do not rebuild):**
- Domain: `app/backend/lib/therobotplans/domains/goals/goals.ex`
- Schemas: `app/backend/lib/therobotplans/schema/{objective,key_result,kr_item_link,okr_checkin}.ex`
- REST: `app/backend/lib/therobotplans_web/controllers/okr_controller.ex` (+ `router.ex` ~L235-238)
- Frontend: `app/frontend/src/app/app/[orgId]/goals/page.tsx` (single file today; no `components/okr/`)
- Migrations: `app/backend/db/changelog/030-okrs.yaml` is the complete current column state; head is `034`.

## 2. Persona, JTBD

**Sarah Kim — Small-Team Engineering Lead** (`personas/sarah-kim`). Owns a team objective
that ladders up to a company objective; her engineers own individual objectives that ladder
up to hers. She reports progress upward and does not want to hand-aggregate.

**JTBD:** *"When my team logs progress in their own context, I want it to roll up my
objective and the company objective automatically, so I can report alignment upward
without a spreadsheet — and I never want a mislink to create a loop or silently corrupt a
number."*

## 3. Functional Requirements

### FR-1 — Hierarchy levels (AC-1)
Objectives support at least three linkage levels via `parent_id`: **organization (company),
team, individual**. `level` (`company|team|individual|personal`) already exists on the
schema and stays as a label; **hierarchy is structural via `parent_id`, not derived from
`level`**. Level is advisory metadata, not a constraint on who may parent whom.

### FR-2 — Child roll-up into parent (AC-2)
A parent objective's progress = aggregate of **(a)** each child objective's rolled-up
progress and **(b)** its own directly-attached KRs, combined under the objective's
`rollup_strategy`. A leaf objective (no children) keeps today's behavior: mean/weighted
fraction of its own KRs. KRs remain item-backed via `kr_item_links` + `recompute_progress/1`
unchanged.

### FR-3 — Configurable rollup strategy (AC-3)
Each objective stores `rollup_strategy`:
- `weighted_avg` (default) — weighted mean of contributors, each contributor weighted by its
  `weight` column (child objective `weight`, KR `weight`). Weights need not sum to 1; the
  engine normalizes by the total weight of present contributors.
- `min_children` — progress = **min** over child + own-KR contributor fractions (worst-case
  reporting). Contributors with no data are skipped.
- `custom` — reserved: stores the strategy key and routes to a pluggable
  `Goals.Rollup` resolver. A full formula DSL is **out of scope** (open question OQ-3);
  `custom` falls back to `weighted_avg` until a resolver is registered.

### FR-4 — Direction correctness in rollup
Rollup must honor KR `direction`. Today both progress functions compute `current/target`
regardless of `direction` and the code comment even says "higher_better". As part of making
rollups trustworthy, `lower_better` KRs contribute `clamp(1 - (current/target), 0, 1)`
against a baseline, and **all** contributor fractions are clamped to `[0, 1]` before
aggregation (a KR exceeding target must not push a parent above 100%). This is a scoped
correctness fix, not a feature expansion.

### FR-5 — Cycle detection (AC-5)
Linking or reparenting an objective so that it becomes its own ancestor is rejected at two
layers: a friendly app-level guard in `update_objective/2` / child-create, and an
authoritative DB trigger (defense in depth — see §4/§5). Self-parent (`parent_id == id`),
direct cycle, and transitive cycle are all rejected with `{:error, :cycle}` → HTTP 422.

### FR-6 — Depth limit
Hierarchy depth is capped at **`@max_depth 6`** (configurable constant). Reparenting that
would push any descendant subtree past the cap is rejected `{:error, :max_depth}` → 422.
Enforced app-side (walk ancestors) and by the same DB trigger. Rationale: bounds recursive
rollup cost and UI nesting.

### FR-7 — Tree view + flat filtered list (AC-4)
The hierarchy is navigable two ways:
- **Tree:** `GET …/objectives/tree` returns the nested forest (roots + descendants) with
  each node's rolled-up progress. Depth-bounded, single query where possible (recursive CTE).
- **Flat filtered list:** the existing `index` (`?level=&status=&owner_id=&project_id=`) is
  retained and gains `?parent_id=` (direct children) and `?root=true` (roots only).

### FR-8 — REST CRUD gaps closed
Add the missing management endpoints (§5): PATCH/DELETE key_results, POST/DELETE KR item
links, DELETE objectives, create child objective, reorder/reparent, list/delete check-ins.
Every new route authorizes via the OkrController org-membership template (§5) — reads
`viewer`, writes `member`.

### FR-9 — Drag-reorder & reparent (UI, cycle-safe) (AC-4/AC-5)
Tree UI supports drag to reorder siblings (`sort_order`) and drag to reparent. The client
pre-checks the drop against the known subtree to disable illegal drops (self/descendant =
would-be cycle, or depth overflow); the server independently re-validates and returns 422 on
violation. UI never assumes success — it reconciles from the server response.

### FR-10 — Delete semantics
Deleting an objective with children requires an explicit policy (OQ-4). Default: **block**
delete of an objective that has children (`{:error, :has_children}` → 409) — the user must
reparent or delete children first. (DB FK is `ON DELETE SET NULL`, which would silently
orphan; the app guard prevents relying on that.) Deleting a leaf objective cascades its KRs
and check-ins (existing FK `ON DELETE CASCADE`).

## 4. Data Model — Liquibase block 140-144

New changelogs under `app/backend/db/changelog/`, appended to `db.changelog-master.yaml`.
All raw-SQL changesets with explicit rollbacks, matching the `030-okrs.yaml` house style
(`author: therobotplans`). **Numbering note:** current head is `034`; the `140-144` range is
the WS-I lane-reserved block (see OQ-1) — the gap 035-139 is intentional lane partitioning,
not an ordering bug.

**140-objectives-rollup-config.yaml** — ALTER `objectives`:
```sql
ALTER TABLE objectives
  ADD COLUMN rollup_strategy varchar(16) NOT NULL DEFAULT 'weighted_avg'
    CHECK (rollup_strategy IN ('weighted_avg','min_children','custom')),
  ADD COLUMN weight numeric NOT NULL DEFAULT 1.0,      -- contribution to its parent
  ADD COLUMN sort_order integer NOT NULL DEFAULT 0;    -- sibling ordering (drag)
-- rollback: DROP COLUMN rollup_strategy, weight, sort_order
```

**141-key-results-weight.yaml** — ALTER `key_results` (weighted objective aggregation):
```sql
ALTER TABLE key_results
  ADD COLUMN weight numeric NOT NULL DEFAULT 1.0;      -- contribution to its objective
-- rollback: DROP COLUMN weight
```

**142-objectives-progress-cache.yaml** — memoized rollup (see §6 performance):
```sql
ALTER TABLE objectives
  ADD COLUMN cached_progress numeric,                  -- last computed 0..1, nullable
  ADD COLUMN cached_progress_at timestamptz;
-- rollback: DROP COLUMN cached_progress, cached_progress_at
```

**143-objectives-tree-indexes.yaml** — tree/rollup access paths:
```sql
CREATE INDEX idx_objectives_org_parent ON objectives (organization_id, parent_id);
CREATE INDEX idx_objectives_parent_sort ON objectives (parent_id, sort_order);
-- rollback: DROP both indexes  (idx_objectives_parent from 030 stays)
```

**144-objectives-cycle-depth-trigger.yaml** — authoritative graph integrity:
```sql
-- Function walks NEW.parent_id's ancestor chain via recursive CTE.
-- Rejects when: NEW.id appears among ancestors (cycle) OR depth would exceed cap.
CREATE OR REPLACE FUNCTION objectives_guard_hierarchy() RETURNS trigger AS $$
DECLARE ancestor_depth int;
BEGIN
  IF NEW.parent_id IS NULL THEN RETURN NEW; END IF;
  IF NEW.parent_id = NEW.id THEN
    RAISE EXCEPTION 'objective_cycle' USING ERRCODE = 'check_violation';
  END IF;
  WITH RECURSIVE anc AS (
    SELECT id, parent_id, 1 AS depth FROM objectives WHERE id = NEW.parent_id
    UNION ALL
    SELECT o.id, o.parent_id, anc.depth + 1
      FROM objectives o JOIN anc ON o.id = anc.parent_id
      WHERE anc.depth < 64            -- hard stop guards against pre-existing bad data
  )
  SELECT max(depth) INTO ancestor_depth FROM anc;
  IF EXISTS (SELECT 1 FROM anc WHERE id = NEW.id) THEN
    RAISE EXCEPTION 'objective_cycle' USING ERRCODE = 'check_violation';
  END IF;
  IF ancestor_depth >= 6 THEN         -- @max_depth; NEW becomes depth ancestor_depth+1
    RAISE EXCEPTION 'objective_max_depth' USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_objectives_guard_hierarchy
  BEFORE INSERT OR UPDATE OF parent_id ON objectives
  FOR EACH ROW EXECUTE FUNCTION objectives_guard_hierarchy();
-- rollback: DROP TRIGGER, DROP FUNCTION
```
The trigger only fires on `parent_id` changes (insert or reparent), so ordinary title/status
updates and KR writes are unaffected. It does not detect depth added *below* a node when a
whole subtree is reparented into a deep slot — that residual is caught app-side in
`update_objective/2` (walk the moved subtree's own max depth + new ancestor depth). Trigger is
the backstop against direct DB writes and races.

**Reused as-is:** `kr_item_links` (weighted item→KR), `recompute_progress/1`, the
`ON DELETE CASCADE` on `key_results`/`okr_checkins`, `ON DELETE SET NULL` on `parent_id`
(FR-10 app guard makes orphaning unreachable through the API).

## 5. Rollup Engine

Extend `Goals` (`domains/goals/goals.ex`). Introduce a `Goals.Rollup` module or private
functions; keep `objective_progress/1`'s public arity but make it hierarchical.

### 5.1 Algorithm
`objective_progress(id)` returns Decimal `0..1`:
1. Load the objective, its `children` (ids + `weight` + `rollup_strategy`), and its own KRs
   (`current/target/direction/weight`).
2. Build a contributor list:
   - each own KR → `frac = kr_fraction(kr)` (direction-aware, clamped `[0,1]`), weight `kr.weight`
   - each child → `frac = objective_progress(child.id)` (recursion), weight `child.weight`
3. Combine per this objective's `rollup_strategy`:
   - `weighted_avg`: `Σ(frac·weight) / Σ(weight)` over present contributors
   - `min_children`: `min(frac)` over present contributors
   - `custom`: `Goals.Rollup.resolve(objective, contributors)` or fall back to `weighted_avg`
4. Empty contributor set → `Decimal.new("0")` (preserves current leaf-with-no-KRs behavior).

`kr_fraction/1`: `higher_better → current/target`; `lower_better → 1 - current/target`; both
clamped to `[0,1]`; `target == 0 → 0`.

### 5.2 Recompute triggers (extend existing hook chain)
Rollup is memoized in `objectives.cached_progress`. Recompute path is **bottom-up**:
- **KR change** (`create_key_result`, `update_key_result`, `link_item`, `unlink_item`,
  `recompute_progress`): after the leaf KR settles, call `recompute_objective_chain(kr.objective_id)`.
- **Item status change:** the existing `items.ex:335 → Goals.item_status_changed/1` hook
  already recomputes each affected KR; append `recompute_objective_chain/1` for each touched
  objective. This reuses the established best-effort (`try/rescue`) pattern so a rollup failure
  never breaks the item write.
- **Child change** (create/delete child, reparent, weight/strategy edit): recompute the moved
  child's new-parent chain and (on reparent) its old-parent chain.

`recompute_objective_chain(objective_id)`: walk `parent_id` upward to the root, recomputing
and writing `cached_progress`/`cached_progress_at` at each level (each level reuses freshly
cached child values → single pass, O(depth), bounded by `@max_depth`). Reads
(`index`/`tree`/Today) serve `cached_progress`, falling back to on-demand computation when
`nil`.

### 5.3 Performance
Depth cap (6) bounds recursion. Bottom-up memoization keeps a KR write O(depth) not O(tree).
The tree endpoint uses one recursive CTE to fetch the forest and serves cached progress —
no N+1. Today's `Today` view (`today.ex:91`) switches to reading `cached_progress`.

## 6. API Surface

All under `scope "/api/v1/organizations/:org_id"`, `pipe_through [:api, :authenticated]`.
Authorization is **mandatory on every route** via the existing OkrController template — the
`with_org_objective/5` helper (reads `viewer`, writes `member`) and a **new**
`with_org_key_result/5` helper that loads the KR, resolves its objective, and asserts
`objective.organization_id == org_id` (blocks cross-org UUID probing, mirrors the objective
helper). This is the "chunk-A authz template" the story depends on — existing routes already
comply; new routes must too.

| Verb | Path | Action | Role | Notes |
|------|------|--------|------|-------|
| GET | `/objectives/tree` | `tree` | viewer | nested forest w/ rolled-up progress (FR-7) |
| GET | `/objectives` | `index` | viewer | + `?parent_id=` `?root=true` filters |
| POST | `/objectives` | `create` | member | accepts optional `parent_id` (child create) |
| POST | `/objectives/:id/children` | `create_child` | member | ergonomic alias; sets `parent_id=:id` |
| PATCH | `/objectives/:id` | `update` | member | title/status/level/period/**rollup_strategy/weight/parent_id/sort_order** — reparent+cycle guarded |
| DELETE | `/objectives/:id` | `delete` | member | FR-10 block-if-children (409) else cascade |
| POST | `/objectives/:id/key_results` | `create_key_result` | member | exists |
| PATCH | `/key_results/:id` | `update_key_result` | member | **new** — title/target/current/unit/direction/status/weight/auto_progress |
| DELETE | `/key_results/:id` | `delete_key_result` | member | **new** |
| POST | `/key_results/:id/items` | `link_item` | member | **new** — body `{item_id, weight}` → `Goals.link_item` |
| DELETE | `/key_results/:id/items/:item_id` | `unlink_item` | member | **new** → `Goals.unlink_item` |
| POST | `/objectives/:id/checkins` | `create_checkin` | member | exists |
| GET | `/objectives/:id/checkins` | `list_checkins` | viewer | **new** |
| DELETE | `/checkins/:id` | `delete_checkin` | member | **new** (via objective→org check) |

Error contract: cycle → `422 {error: "cycle"}`; depth → `422 {error: "max_depth"}`;
delete-with-children → `409 {error: "has_children"}`; cross-org / missing → `404`
(same as `with_org_objective` today, avoids existence disclosure).

## 7. Frontend — `app/frontend/src/app/app/[orgId]/goals/**` + `components/okr/**`

**Convention correction:** the codebase uses the `api` object from `@/lib/api` directly;
`useApi` exists but is unused project-wide — follow the existing `goals/page.tsx` pattern
(`api.listObjectives(orgId).then(...)`), do **not** introduce `useApi`.

New `api` client methods (`src/lib/api.ts`): `getObjectiveTree`, `updateObjective`
(reparent/strategy/weight/sort_order), `deleteObjective`, `createChildObjective`,
`updateKeyResult`, `deleteKeyResult`, `linkKrItem`, `unlinkKrItem`, `listCheckins`,
`deleteCheckin`. (`updateObjective`, `createKeyResult`, `createCheckin` already exist.)

New components under `src/components/okr/`:
- `okr-tree.tsx` — collapsible hierarchy; each node shows title, `level` badge, rolled-up
  `ProgressBar` (from `cached_progress`), expand toggle, child count; lazy-loads subtree or
  consumes the tree endpoint.
- `okr-node.tsx` — a single objective row: inline KR list, strategy selector
  (`weighted_avg|min_children|custom`), weight input, create-child action, edit/delete.
- `kr-editor.tsx` — inline KR create/edit (title/target/current/unit/direction/weight/
  auto_progress); item-link add/remove sub-panel.
- `checkin-modal.tsx` — create check-in (`Dialog` + `Textarea`), list + delete history.
- `reorder.ts` — drag helpers: computes legal drop targets client-side (excludes self +
  descendants, enforces depth cap), reconciles from server 422.

Reuse `@/components/ui` primitives: `dialog`, `button`, `input`, `select`, `textarea`,
`progress-bar`, `section-card`, `empty-state`, `badges`, `field-label`, `spinner`.
(Note the current page pulls `ProgressBar/SectionCard/Empty` from
`@/components/pm/priority-badge`; standardize new work on `@/components/ui` and migrate the
page's imports as a small cleanup.)

`goals/page.tsx` is refactored to mount `<OkrTree>` (tree default) with a flat-list toggle
that reuses the existing `index` filter UI; the existing create-objective form stays.

## 8. Acceptance Tests

Backend (ExUnit, `test/therobotplans/domains/goals/`):
1. **Rollup math — weighted_avg mixed:** parent with 2 child objectives (weights 2,1) + 1 own
   KR (weight 1) → assert Decimal equals `Σ(frac·w)/Σw`. Child fracs themselves computed from
   their own KRs.
2. **Rollup math — min_children:** same tree, `rollup_strategy=min_children` → assert min
   contributor fraction; contributors with no data skipped.
3. **Direction + clamp:** `lower_better` KR (`current<target`) contributes `1-current/target`;
   a KR with `current>target` contributes exactly `1.0` (clamped), parent never exceeds 1.0.
4. **Item-link weight change recompute:** flip a linked item to `done`, then change a link
   `weight` → assert leaf KR `current_value` and **every ancestor** `cached_progress` update
   (chain recompute), via the `item_status_changed` hook path.
5. **Cycle rejection:** self-parent, direct A→B→A, transitive A→B→C→A each return
   `{:error, :cycle}` at the domain layer AND raise the DB trigger on forced direct write.
6. **Depth cap:** building a chain to depth 6 succeeds; the 7th reparent returns
   `{:error, :max_depth}`; reparenting a 2-deep subtree under a 5-deep node (would be 7) is
   rejected app-side.
7. **Delete policy:** delete objective-with-children → `{:error, :has_children}`; delete leaf
   → KRs + check-ins cascade gone.

Controller/PBAC (`test/therobotplans_web/controllers/okr_controller_test.exs`):
8. **Cross-org denial:** user in org A hitting every new route (PATCH/DELETE KR, link/unlink,
   DELETE objective, tree, child-create, checkin list/delete) for an org-B resource → `404`,
   no mutation.
9. **Role gating:** `viewer` blocked from every write route; `member` allowed; unauthenticated
   → 401.
10. **Error contracts:** cycle→422, depth→422, has_children→409 surface with the documented
    JSON bodies.

Frontend (component/integration): tree renders rolled-up bars; illegal drag targets disabled;
server 422 on a raced drop reconciles the tree back; inline KR create/edit and check-in modal
round-trip.

## 9. Dependencies, Out-of-Scope, Open Questions

**Depends on:**
- OkrController org-membership authz template (`with_org_objective/5`) — already implemented;
  US-069 adds the parallel `with_org_key_result/5` following it. No pre-existing authz gap was
  found (contrary to the brief's assumption), so this is *extend*, not *fix*.
- `Goals.recompute_progress/1` + `kr_item_links` (reused unchanged for leaf KRs).
- Items domain hook `items.ex:335 → Goals.item_status_changed/1` (extended with chain recompute).

**Out of scope:**
- US-013 + US-074 personal-OKR **visibility/permission layer** (merged M3 WS-I, Flag 1) — this
  PRD delivers the hierarchy + rollup only; per-viewer scoping of who sees which objective is M3.
- Full `custom` rollup **formula DSL** — only the pluggable-resolver seam ships now.
- OKR scoring (US-073), check-in agent (US-071).

**Open questions:**
- **OQ-1 (numbering):** Confirm the `140-144` block is the intended WS-I lane reservation given
  current head `034` and empty 035-139. If lanes are not partitioned by number, renumber to
  `035-039` to keep contiguous apply order.
- **OQ-2 (persona):** Brief anticipated Lin/James (leadership); the actual story persona is
  **sarah-kim** (small-team eng lead). Confirm no leadership persona needs to be added to AC.
- **OQ-3 (custom formula):** Is a stored-expression/DSL wanted later, or is `weighted_avg` +
  `min_children` sufficient and `custom` should be dropped from the CHECK constraint?
- **OQ-4 (delete policy):** Block-if-children (proposed) vs. reparent-children-to-grandparent
  vs. cascade-delete-subtree. Default assumed: block.
- **OQ-5 (direction fix blast radius):** Honoring `lower_better` + clamping changes numbers the
  flat `objective_progress` previously produced. Acceptable as a correctness fix, or gate behind
  a flag to avoid moving existing dashboards?
