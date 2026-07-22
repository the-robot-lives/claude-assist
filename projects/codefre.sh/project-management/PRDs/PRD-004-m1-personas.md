---
id: PRD-004
title: "M1 Lane C — Personas (authoring primitive)"
status: draft
milestone: M1
lane: "C — Personas"
stories: [US-035, US-036, US-051, US-053, US-055, US-116]
created: 2026-07-22
updated: 2026-07-22
---

# PRD-004 — M1 Lane C: Personas

**Author**: npl-prd-editor · **Roadmap**: `project-management/roadmap/02-M1-authoring-primitives.md` (Lane C) · **Data model**: `docs/arch/data-model.md` §5.4, §6.2, §14.11

## 1. Overview

Personas are the third versioned authoring primitive (alongside prompts and rubrics). A
persona is a reusable "user lens" — a tone tag plus optional system preamble and, later,
node-scoped expectation overlays — that modulates how the runner drives an agent under test.
This PRD delivers the persona primitive's **create → edit → publish version → browse/reuse**
loop in UI and API, plus the schema-side hooks that later milestones (M2 expectations, M3
runner) build on.

### Goals

1. Authors can create a persona with a tone tag, publish immutable versions, and browse/reuse
   personas across the org (US-035).
2. The schema and selection contract exist for attaching a persona to a run — the `run_personas`
   join and a run-form persona picker — without the runtime prompt mutation (US-036, schema side).
3. A persona version can reference a published prompt as a **system preamble** (US-053).
4. Authors can seed personas from a code-shipped **starter library** of calibrated lenses (US-055).
5. Schema stubs are in place for persona-layered expectations (US-051) and marketplace import
   (US-116) so M2 and Wave 3 land without a migration rewrite.

### Non-Goals (this milestone)

- **US-052 multi-persona fan-out** and **US-118 mid-run persona switching** — owned by M3.
- **US-054 per-persona results breakdown** — owned by M4 (needs the results layer).
- Runtime prompt mutation / preamble injection — the runner is M3. M1 stores the data the
  runner will read; it does not execute a run.
- Any rating/review UI for the marketplace.

The data model must not preclude the above; §5 calls out the columns that keep them open.

## 2. Background & current state

- **No migrations exist yet.** `docs/arch/data-model.md` is documentation-only; M0 authored the
  Wave-1 migrations. This PRD's schema work is migration steps **6** (`create_personas_and_versions`),
  **9** (`create_persona_expectations`, stub), and the persona half of step **10**
  (`create_runs_and_personas`) from §10 of the data model.
- **Dependency ordering.** `persona_versions.system_prompt_version_id → prompt_versions`, so
  personas migrate after prompts (Lane A). `persona_expectations` FKs `script_nodes`, which do
  **not** exist until M2 — hence US-051 is a schema stub only here (see §4.3).
- **Entry criteria** (roadmap): M0 exit — migrations live, CI green, auth + org membership working;
  OpenAPI spec frozen.
- **Exclusive surfaces** (roadmap): `app/backend/lib/codefresh/personas/`, persona list/detail
  screens in `app/frontend/`. Screens already specced: `13-persona-list`, `14-persona-detail`,
  `33-persona-library-modal`, `34-persona-marketplace` (`28-persona-heatmap` is M4, out of scope).

## 3. Data model

Persona tables follow the head + version-table copy-on-write pattern shared by all authored
entities (data model §5). **Field names below are authoritative for TDD.**

### 3.1 `personas` (head)

Common head shape only: `id uuid pk`, `organization_id uuid fk not null`, `slug citext not null`,
`name text not null`, `description text`, `current_version_id uuid fk nullable`,
`archived_at utc_datetime nullable`, `created_by_user_id uuid fk nullable`, `inserted_at`,
`updated_at`.

- Unique: `(organization_id, slug)`
- `current_version_id` is nullable until the first version publishes; **auto-advances** to the
  latest published version (data model open Q#7, recommended default).

### 3.2 `persona_versions` (immutable)

Common version shape — `id uuid pk`, `persona_id uuid fk not null`, `organization_id uuid fk`
(denorm), `version_number integer not null`, `checksum bytea not null`,
`published_by_user_id uuid fk nullable`, `inserted_at utc_datetime not null` (no `updated_at`) —
plus:

| Column | Type | Null | Notes |
|---|---|---|---|
| `tone` | text | yes | free-text tone tag (`broken-english`, `hostile`, …) |
| `description` | text | yes | version-pinned description (head `description` is the catalog blurb) |
| `system_prompt_version_id` | uuid | yes | FK → `prompt_versions`; optional persona-wide preamble (US-053) |
| `metadata` | jsonb | no `'{}'` | tags; `imported_from` provenance pointer (US-055/US-116) |

- Unique: `(persona_id, version_number)`
- Unique: `(persona_id, checksum)` — idempotent re-publish
- Index: `(organization_id)`, `(system_prompt_version_id)`
- **Checksum** is computed over canonical content `{tone, description, system_prompt_version_id, metadata(excluding imported_from)}`. Republishing identical content returns the existing row.

### 3.3 `run_personas` (US-036, schema side)

Join pinning which persona version(s) a run includes. Table lands in M1; the run-trigger write
path is exercised by the M3 runner.

`id uuid pk`, `run_id uuid fk → runs (on delete cascade)`, `persona_version_id uuid fk → persona_versions`,
`organization_id uuid fk` (denorm), `inserted_at utc_datetime not null`.

- Unique: `(run_id, persona_version_id)`
- Index: `(persona_version_id)`
- The many-row shape (one run → many persona rows) is what keeps US-052 fan-out open — M1 writes
  at most one row per run, but nothing in the schema caps it at one.

### 3.4 `persona_expectations` (US-051, schema stub)

Extra expectations layered on a script node when a persona is active. **Migration only in M1** —
no rows can be inserted until `script_nodes` exist (M2). Columns:

`id uuid pk`, `persona_version_id uuid fk → persona_versions (cascade)`,
`script_node_id uuid fk → script_nodes (cascade)`, `organization_id uuid fk` (denorm),
`label text not null`, `weight numeric(4,3) not null default 1.000`,
`direction text not null default 'positive'` (`:positive` | `:negative`),
`scoring_method text not null` (same enum as `expectations`: `:lm_judge | :rubric | :regex | :semantic | :structural`),
`config jsonb not null default '{}'`, `rubric_version_id uuid fk nullable`,
`reference_embedding vector(1536) nullable`, `inserted_at utc_datetime not null`.

- Unique: `(persona_version_id, script_node_id, label)`
- Index: `(script_node_id)`, `(persona_version_id)`
- Check (method coherence, mirrors `expectations`): `rubric_version_id` required iff
  `scoring_method='rubric'`; `reference_embedding` required iff `scoring_method='semantic'`.

### 3.5 `marketplace_personas` (US-116, P2 / Wave 3 stub)

Cross-org publication table (data model §14.11). Included for completeness; the import flow is P2.

`id uuid pk`, `persona_version_id uuid fk (cascade)`, `author_organization_id uuid fk (restrict)`,
`title text not null`, `description text nullable`, `published_at utc_datetime not null`,
`download_count integer not null default 0`, `average_rating numeric(3,2) nullable`,
`curation_status text not null default 'pending'` (`:pending | :approved | :featured | :flagged`),
`inserted_at`.

- Index: `(curation_status, published_at DESC)`, `(author_organization_id)`

## 4. Requirements per story

### 4.1 US-035 — Create a basic persona with a tone tag (P0)

- **FR-035-1** `POST /api/v1/personas` creates a persona head (draft, no version) with
  `name`, `slug`, optional `description`. `slug` unique per org.
- **FR-035-2** `POST /api/v1/personas/:slug/versions` publishes a `persona_versions` row with a
  computed `checksum` and monotonic `version_number`, and advances `personas.current_version_id`.
  Body: `tone` (free text), optional `description`, optional `system_prompt_version_id`, `metadata`.
- **FR-035-3** Tone is free-text; the persona-detail UI surfaces starter suggestions
  `broken-english`, `hostile`, `confused-novice`, `adversarial`, `over-specific`, `context-switch`.
- **FR-035-4** Published personas (head with non-null `current_version_id`, not archived) appear in
  the run-configuration persona picker.
- **FR-035-5** `tone` is indexed/queryable so Wave-2 "find personas by tone" needs no schema change
  (satisfied by storing `tone` on the version + an org-scoped list query).

### 4.2 US-036 — Attach a persona to a run — SCHEMA SIDE ONLY (P0)

**Boundary (explicit):** M1 delivers the `run_personas` schema (§3.3), a `Personas` context
resolver that maps a persona `slug` → its `current_version_id` for pinning, and the persona-picker
component on the run-trigger form. **The runtime — writing `run_personas` on trigger and mutating
outgoing prompts per the persona's tone — lands with the M3 runner (US-015 owns the trigger form).**
Do not implement prompt mutation here.

- **FR-036-1** The run-trigger form (M3 surface) exposes an optional persona picker populated by
  FR-035-4; selecting a persona yields its pinned `persona_version_id`.
- **FR-036-2** `run_personas` enforces `UNIQUE (run_id, persona_version_id)`; running the same
  script with and without a persona produces two distinct runs (no upsert) — an M3 acceptance the
  schema must support, verified here only at the constraint level.

### 4.3 US-051 — Persona-layered expectations on nodes — SCHEMA STUB (P1)

**Boundary (explicit):** M1 ships the `persona_expectations` migration (§3.4) and nothing else —
`script_nodes` do not exist until M2, so no authoring UI or runtime evaluation is possible yet.
**Finalizes in M2** (authoring from persona detail, runtime evaluation of base + persona
expectations, distinct results display, cross-org validation).

- **FR-051-1** The migration creates `persona_expectations` with all constraints in §3.4.
- **FR-051-2** (M2, documented not built) authoring, runtime layering, results distinction.

### 4.4 US-053 — System-prompt preamble on a persona (P1)

- **FR-053-1** `persona_versions.system_prompt_version_id` references a **published** prompt version
  in the **same org**. Publish rejects an unpublished or cross-org reference (§7).
- **FR-053-2** Persona-detail editor offers a preamble picker over published prompts.
- **FR-053-3** Ordering convention (documented for the M3 runner; not executed here):
  **persona preamble → script system node → user turns.** Preamble is optional; personas without
  one are unaffected. Users cannot reorder this.

### 4.5 US-055 — Import from shared starter library (P1)

- **FR-055-1** A code-shipped YAML manifest defines the starter library, versioned with the app at
  `app/backend/priv/persona_library/*.yaml` (or a single `starter_personas.yaml`). Each entry:
  `key`, `name`, `tone`, `description`, `sample_system_preamble` (text).
- **FR-055-2** `GET /api/v1/persona-library` lists starter personas (name, tone, description,
  preamble preview) — no DB rows, read from the manifest.
- **FR-055-3** `POST /api/v1/personas/import-library` with `{ "library_key": "hostile" }` **deep
  copies** into the caller's org: a fresh `personas` head + `persona_versions` v1. The imported
  persona is fully editable and independent of the manifest.
- **FR-055-4** Slug collision on import auto-suffixes (`hostile`, `hostile-2`) rather than failing.
- **FR-055-5** **Starter seed set (initial library):**

  | key | tone | one-line description |
  |---|---|---|
  | `broken-english` | broken-english | Non-native speaker; fragmented grammar, misspellings, literal phrasing |
  | `hostile` | hostile | Angry, impatient, profane-adjacent; demands, threats to churn |
  | `confused-novice` | confused-novice | No domain vocabulary; vague asks, needs hand-holding |
  | `adversarial` | adversarial | Deliberate probing / jailbreak attempts, prompt-injection bait |
  | `over-specific` | over-specific | Floods with excessive constraints and irrelevant detail |
  | `context-switch` | context-switch | Abruptly changes topic mid-conversation; abandons prior thread |

  Sample preambles ship in the manifest; the six keys match the README tone tags and US-035 suggestions.

### 4.6 US-116 — Import from shared marketplace (P2, deferred)

Forward-looking; schema in §3.5, flow deferred to Wave 3. When built:

- **FR-116-1** `GET /api/v1/marketplace/personas` lists publicly-shared, non-flagged persona
  versions across orgs (title, author org, `download_count`, `average_rating`, `published_at`).
- **FR-116-2** `POST /api/v1/personas/import-marketplace` `{ "marketplace_persona_id": … }`
  deep-copies exactly like FR-055-3, stamping `metadata.imported_from = {"source":"marketplace","marketplace_persona_id":…}`
  and incrementing `download_count`.
- **FR-116-3** Org admins can opt out of marketplace (org `settings.marketplace_opt_out`).

## 5. API surface

All routes are org-scoped by the authenticated membership (`organization_id` from JWT); no path
org segment. JSON. `slug` is the head identifier in the path.

| Method | Path | Story | Notes |
|---|---|---|---|
| GET | `/api/v1/personas` | US-035 | list org personas (name, slug, tone of current version, current_version_number, archived) |
| POST | `/api/v1/personas` | US-035 | create head; body `{name, slug, description?}` → 201 |
| GET | `/api/v1/personas/:slug` | US-035 | detail incl. version history |
| PATCH | `/api/v1/personas/:slug` | US-035 | edit head `name`/`description` (mutable); slug immutable |
| POST | `/api/v1/personas/:slug/versions` | US-035, US-053 | publish version `{tone?, description?, system_prompt_version_id?, metadata?}` → 201 (or 200 if checksum matches latest) |
| GET | `/api/v1/personas/:slug/versions/:n` | US-035 | fetch a pinned version |
| POST | `/api/v1/personas/:slug/archive` | US-035 | set `archived_at`; removes from run picker |
| GET | `/api/v1/persona-library` | US-055 | starter library manifest listing |
| POST | `/api/v1/personas/import-library` | US-055 | `{library_key}` → deep copy → 201 |
| GET | `/api/v1/marketplace/personas` | US-116 (P2) | deferred |
| POST | `/api/v1/personas/import-marketplace` | US-116 (P2) | deferred |

`run_personas` has **no dedicated M1 endpoint** — it is written by the M3 run-trigger controller
(US-015). The `Personas` context exposes `resolve_for_pinning(slug_or_id)` → `{:ok, persona_version_id}`
for that consumer.

## 6. UI surface

- **Persona List** (`13-persona-list`): table of personas (name, slug, tone, current version,
  published status); **New Persona**, **Import from Library**, **Marketplace** (P2, hidden or
  disabled if opted out) buttons; row → detail.
- **Persona Detail** (`14-persona-detail`): name/slug/description; tone tag input with the six
  suggestions; **system-preamble picker** over published prompts (US-053); **Publish** → immutable
  version; version history. Persona-expectations section is present but **disabled/"coming in M2"**
  (US-051 stub).
- **Persona Library Modal** (`33-persona-library-modal`): starter list with preview panel (name,
  tone, description, sample preamble); **Import** → deep copy → navigates to new persona detail.
- **Persona Marketplace** (`34-persona-marketplace`): P2, deferred.
- Run-trigger persona picker: component contract only (populated from FR-035-4); wired by M3.

## 7. Error cases

| Condition | Response |
|---|---|
| Create/import with slug already in org | 409 Conflict (create); import auto-suffixes (FR-055-4) |
| Publish version referencing cross-org `system_prompt_version_id` | 422 Unprocessable — cross-org reference |
| Publish referencing a non-existent or unpublished prompt version | 422 Unprocessable |
| Republish identical canonical content (checksum match on latest) | 200 OK, returns existing version (idempotent), no new row |
| Publish to an archived persona | 409 Conflict |
| `import-library` unknown `library_key` | 404 Not Found |
| PATCH attempting to change `slug` | 422 Unprocessable — slug immutable |
| `persona_expectations` insert with cross-org `script_node_id` (M2) | 422 — tenancy check (documented, enforced in M2) |
| Any request without org membership | 401 / 403 per auth layer |

## 8. Non-functional

| NFR | Requirement |
|---|---|
| Tenancy | Every persona query filtered by `organization_id`; no cross-org read/write except the P2 marketplace publication surface. |
| Immutability | `persona_versions` rows never update; edits publish a new version. Enforced by convention (optional trigger, data-model step 18). |
| Versioning | `version_number` assigned inside the publish txn via `SELECT max(version_number) … FOR UPDATE` on the head. Idempotent by `(persona_id, checksum)`. |
| Test coverage | ≥ 80% line coverage on `lib/codefresh/personas/`. |
| Performance | Persona list and picker queries < 100 ms at MVP scale (org-scoped, indexed). |
| Manifest integrity | Starter-library YAML validated at boot/CI; malformed manifest fails the build, not runtime. |

## 9. Acceptance criteria (Given/When/Then, TDD-ready)

**US-035**
- Given an authed member, When `POST /api/v1/personas {name, slug}`, Then a `personas` head exists
  with `current_version_id = null` and `(organization_id, slug)` unique.
- Given a draft persona, When `POST …/versions {tone:"hostile"}`, Then a `persona_versions` row
  exists with `version_number=1`, a non-null `checksum`, and `current_version_id` now points to it.
- Given two publishes of identical content, When the second is posted, Then no second row is created
  and the response returns the first version (200).
- Given a published, non-archived persona, When the run-config picker loads, Then the persona appears.

**US-036 (schema side)**
- Given the migration applied, When inspecting the schema, Then `run_personas` exists with
  `UNIQUE (run_id, persona_version_id)` and FKs to `runs` and `persona_versions`.
- Given a persona slug, When `Personas.resolve_for_pinning(slug)` is called, Then it returns the
  `current_version_id` of the published persona (or `{:error, :not_published}`).
- (M3, documented) Given a run triggered with a persona, Then one `run_personas` row is written and
  a run without a persona writes none — two distinct runs, no upsert.

**US-051 (schema stub)**
- Given the migration applied, When inspecting the schema, Then `persona_expectations` exists with
  `UNIQUE (persona_version_id, script_node_id, label)` and the method-coherence check constraint.
- (M2, documented) authoring, runtime layering, distinct results display.

**US-053**
- Given a published prompt in the same org, When publishing a persona version with that
  `system_prompt_version_id`, Then the version persists the reference.
- Given a prompt version in another org, When publishing with it, Then the request is rejected 422.
- Given a persona with no preamble, When it is used, Then behavior is unchanged (nullable field).

**US-055**
- Given the starter manifest, When `GET /api/v1/persona-library`, Then all six seed personas return
  with name, tone, description, and preamble preview.
- Given `POST …/import-library {library_key:"broken-english"}`, Then a new head + `persona_versions`
  v1 exist in the caller's org, independent of the manifest, editable.
- Given a slug collision on import, When importing, Then the slug is auto-suffixed and import succeeds.

**US-116 (P2)**
- Deferred; schema present (`marketplace_personas`). No M1 acceptance beyond migration existence.

## 10. Out of scope

- US-052 multi-persona fan-out, US-118 mid-run switching (M3); US-054 per-persona results (M4).
- Runtime prompt mutation / preamble injection / run execution (M3).
- Persona-expectation authoring & runtime (M2); `replaces_expectation_id` overlay and per-persona
  weight overrides (Wave 3).
- Marketplace rating/review UI, moderation beyond `curation_status`, monetization.
- Persona heatmap screen (`28-persona-heatmap`, M4).

## 11. Dependencies & gates

- **Depends on** Lane A prompts (`prompt_versions` must exist for `system_prompt_version_id`).
- **Migration order**: step 6 `create_personas_and_versions` (after prompts), step 9
  `create_persona_expectations` (after `script_nodes` land — M2 for real rows; the migration may
  ship in M1 only if `script_nodes` exists, else it moves to M2 — see Open Q #1), persona half of
  step 10 `create_runs_and_personas` (needs `runs`).
- **Gate**: M1 exit requires persona create/version/publish/list working in UI + API, and the
  cross-primitive stub reference (persona-id addressable from run/script fixtures) resolving.

## 12. Open questions

1. **`persona_expectations` migration timing.** It FKs `script_nodes`, an M2 primitive. Ship the
   migration in M1 (table empty, decouples schema) or defer the whole migration to M2 with the
   authoring UI? Recommend: defer to M2 alongside `script_nodes` to avoid a dangling FK target.
2. **`run_personas` / `runs` timing.** `runs` is an M3 primitive. Does the `run_personas` migration
   ship in M1 (schema-only, per the brief) or with `runs` in M3? Recommend: ship in M3 with `runs`;
   in M1 deliver only the `Personas.resolve_for_pinning` contract and the picker component. (Brief
   says "schema side"; flagging the ordering conflict rather than resolving it.)
3. **`current_version_id` semantics** — auto-advance vs explicit promote (data-model open Q#7). This
   PRD assumes auto-advance.
4. **Import provenance for library imports.** Store `metadata.imported_from = {"source":"library","key":…}`
   on the v1 — confirm we want the pointer for starter imports, not just marketplace.
