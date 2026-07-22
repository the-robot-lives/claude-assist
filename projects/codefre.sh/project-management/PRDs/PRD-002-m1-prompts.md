---
id: PRD-002
title: "M1 Lane A — Prompts Domain"
status: draft
milestone: M1
lane: "A — Prompts"
stories: [US-009, US-010, US-011, US-048, US-049, US-050, US-114, US-115]
created: 2026-07-22
updated: 2026-07-22
---

# PRD-002 — M1 Lane A: Prompts Domain

**Roadmap ref:** `project-management/roadmap/02-M1-authoring-primitives.md` (Lane A, impl-plan Stage 1)
**Data-model ref:** `docs/arch/data-model.md` §5.1 (`prompts` / `prompt_versions`), §5.2 (`script_nodes.prompt_version_id`)
**Backend zone:** `app/backend/lib/codefresh/prompts/` + `CodefreshWeb.PromptController`
**Frontend zone:** prompt library + prompt detail screens in `app/frontend/`

---

## 0. READ THIS FIRST — the backend is already scaffolded

Direct inspection of the `develop` checkout (2026-07-22) shows the prompts **Elixir backend
is substantially implemented already**. This PRD is written against the code on disk, not a
greenfield assumption. Two genuine gaps remain (schema migration + tests); everything else is
"verify and finish", not "build from scratch".

| Surface | State on disk | Implication for this milestone |
|---|---|---|
| `Codefresh.Prompts` context | **Exists** (`lib/codefresh/prompts.ex`) — CRUD, `list_prompts/2` w/ usage count, `publish_version/2`, `sandbox_render/1`, `resolve_current_version/2`, `pinnable?/2` | Verify + test; do not re-author signatures |
| `Prompt` / `PromptVersion` schemas | **Exist** (`prompts/prompt.ex`, `prompt_version.ex`) — changesets, slug derivation, `compute_checksum/3` | Verify + test |
| `Template` engine | **Exists** (`prompts/template.ex`) — `{{var}}` **and** `{% if %}`/`{% for %}` extract, validate, render | US-048 **and** US-115 render path already land here |
| `ToolDefs` | **Exists** (`prompts/tool_defs.ex`) — adapter-agnostic validate + `tool_names/1` | US-049 backend done; needs frontend + expectation wiring |
| `PromptController` | **Exists** (`codefresh_web/controllers/prompt_controller.ex`) — index/create/show/update/archive/publish/current_version/sandbox | Verify + test |
| Routes | **Exist** (`router.ex:214-226`, `:307`) under `/api/v1/organizations/:organization_id/prompts` | Do not renumber/rename |
| **Liquibase migration for `prompts` / `prompt_versions`** | **MISSING** — highest changelog is `024`; no table DDL. Ecto schemas reference tables that the DB does not yet have | **GAP-1 — blocker.** New changelog `025-prompts.yaml` must be authored before any test runs (`docs/arch/data-model.md` §10 step 3) |
| **Test suite for prompts** | **MISSING** — `find test -iname '*prompt*'` returns nothing | **GAP-2.** TDD Tester authors context + controller + template tests from §11 |
| `Scripts.attach_prompt/2` + route | **Exists** (`script_controller.ex:151`) but the `script_nodes` table is M2 | US-011 is **schema-stub-only** here (see §1, §5.3) |

---

## 1. Overview

Ship prompts as the first versioned authoring primitive: a **head + immutable-version** entity
(`prompts` → `prompt_versions`) that script nodes will pin by exact `prompt_version_id`. This lane
delivers create → edit → publish version → browse/reuse in both API and UI, plus template
variables, tool/function schemas, and a render-only testing sandbox.

### Goals

1. Prompt heads are first-class, org-scoped, slug-addressable, and archivable (US-009).
2. Publishing snapshots the draft body into an **immutable** `prompt_versions` row with a
   monotonic `version_number` and a content checksum enabling idempotent re-publish (US-010).
3. Script nodes pin a specific published version, never the head — reproducibility guarantee
   (US-011, **schema-stub scope** this milestone).
4. Template variables (`{{var}}`) are declared, and publish rejects any undeclared reference
   (US-048); loops/conditionals (`{% for %}` / `{% if %}`) render deterministically (US-115).
5. Adapter-agnostic tool/function schemas ride on a version and expose their names to structural
   expectations (US-049).
6. The org prompt library is searchable, tag-filterable, and reports per-prompt usage count
   (US-050).
7. A render-only sandbox previews a substituted body without creating a run (US-114, **render
   only** — live agent invocation deferred to Stage 4/M2 when adapters land).

### Non-Goals (this milestone)

- Rollback-to-version UI, cross-version diff (US-010 out-of-scope → Wave 2).
- Bulk "update all nodes to latest", diff-preview-before-update (US-011 → Wave 2).
- Live LLM sandbox invocation, sandbox cost budget, last-5 history compare (US-114 tails → after
  Agents/M2).
- Run-level variable override, persona-metadata binding (US-048 tails → Wave 3).
- Tool-response stubbing/mocking registry (US-049 → Wave 3).
- Cross-org prompt sharing / marketplace, context-based recommendation (US-050 → post-MVP).

---

## 2. Background & current state

`docs/arch/data-model.md` §5 defines the shared head/version pattern: heads carry
`id, organization_id, slug, name, description, current_version_id (nullable until first publish),
archived_at, created_by_user_id, timestamps` with `UNIQUE (organization_id, slug)`; version tables
carry `id, prompt_id, organization_id, version_number, checksum, published_by_user_id, inserted_at`
(no `updated_at` — immutable) with `UNIQUE (prompt_id, version_number)` and `UNIQUE (prompt_id,
checksum)`. §9 invariants: version tables immutable; `version_number` monotonic per head; runs pin
exact IDs; checksums make publish idempotent.

The backend already encodes all of this (see §0). The **template-variable syntax is decided and
implemented**: a hand-rolled minimal engine (NOT minijinja / full Jinja) supporting `{{var}}`
substitution plus `{% if var %}…{% endif %}` and `{% for x in list %}…{% endfor %}` with nesting.
This satisfies US-048 and the US-115 render path in one engine; US-115's remaining scope is
validation coverage, the debug/preview view, and frontend affordances.

---

## 3. Data model

### 3.1 `prompts` (head)

Common head shape (`data-model.md` §5, §5.1). Columns: `id uuid pk`, `organization_id uuid fk not
null`, `slug citext not null`, `name text not null`, `description text`, `current_version_id uuid fk
nullable`, `archived_at utc_datetime nullable`, `created_by_user_id uuid fk nullable`,
`inserted_at`, `updated_at`.

- **Unique:** `(organization_id, slug)` — index name **`prompts_organization_id_slug_index`**
  (the schema's `unique_constraint/2` names this exactly — the migration must match).
- Slug: lowercase `^[a-z0-9][a-z0-9-]*$`, ≤120 chars; auto-derived from `name` when omitted
  (`Prompt.derive_slug/1`: downcase, non-alphanumerics → `-`, trim `-`).
- `current_version_id` FK → `prompt_versions(id)` is **deferrable / nullable** (set after first
  publish; a chicken-and-egg FK — author the migration so head can be inserted before any version).

### 3.2 `prompt_versions` (immutable version)

Common version shape + version-specific columns (`data-model.md` §5.1):

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | no | `gen_random_uuid()` | PK |
| `prompt_id` | uuid | no | | FK → `prompts`, on delete cascade |
| `organization_id` | uuid | no | | denorm for tenancy filters |
| `version_number` | integer | no | | monotonic per prompt, `> 0` |
| `body` | text | no | | rendered template text |
| `template_vars` | jsonb | no | `'{}'` | `{"name" => {"description","default","required"}}` |
| `tool_defs` | jsonb | no | `'{}'` | canonical tool shape (§5.2); code stores `{}` not `[]` |
| `metadata` | jsonb | no | `'{}'` | tags / eval_tags / notes |
| `checksum` | bytea | no | | SHA-256 of canonical `body + template_vars + tool_defs` |
| `published_by_user_id` | uuid | yes | | |
| `inserted_at` | utc_datetime | no | | immutable; **no `updated_at`** |

- **Unique:** `(prompt_id, version_number)`, `(prompt_id, checksum)` (idempotent re-publish).
- **Note vs. data-model.md:** the schema doc lists `tool_defs` default `'[]'`; the *code* defaults
  `tool_defs` and `metadata` to `'{}'` and the canonical tool payload is `%{"tools" => [...]}`.
  **Author the migration to match the code (`'{}'`)**; this is an intentional divergence to record.

### 3.3 `script_nodes.prompt_version_id` — US-011 stub only

`script_nodes` is an **M2** table (`data-model.md` §5.2). In M1 the prompts side only guarantees a
version is **resolvable and pinnable**: `Prompts.resolve_current_version/2` (→ `{:ok, version}` |
`{:error, :not_published}` | `{:error, :not_found}`) and `Prompts.pinnable?/2` (org-scoped existence
check). `list_prompts/2`'s usage-count join references `"script_nodes"` as a raw table name and
must tolerate the table's absence pre-M2 (LEFT JOIN → 0). No `script_nodes` DDL is authored here.

### 3.4 Migration — GAP-1

Author `db/changelog/025-prompts.yaml` (add `- include:` to `db.changelog-master.yaml` after
`024`). Raw-SQL changeSets in house style (`gen_random_uuid()` PKs, `citext`, `CHECK`, explicit
indexes, `rollback`). Creates `prompts` then `prompt_versions` with the constraints above. Per
`data-model.md` §10 this is step 3 (after organizations/002, before rubrics which FK prompt
versions). Test harness applies changelogs before `mix test` (see NPL/codefresh Liquibase recipe).

---

## 4. API surface

All routes live under `scope "/api/v1", pipe_through [:api, :authenticated]` (`router.ex:202`).
Base path: **`/api/v1/organizations/:organization_id/prompts`**. Authorization uses
`Organizations.authorize(user, org_id, role)` — **`"viewer"` for reads, `"editor"` for writes** —
returning `403` on `:forbidden` and `404` on `:not_a_member` (membership existence is not leaked).

| Method | Path | Action | Story | Success | Notable errors |
|---|---|---|---|---|---|
| GET | `/…/prompts` | `index` | US-050 | 200 `{prompts:[…]}` | 403/404 |
| POST | `/…/prompts` | `create` | US-009 | 201 `{prompt}` | 422 `{errors}`; 400 shape |
| GET | `/…/prompts/:id` | `show` | US-009/010 | 200 `{prompt,current_version,versions}` | 404 |
| PATCH | `/…/prompts/:id` | `update` | US-009 | 200 `{prompt}` | 422 `{errors}` |
| DELETE | `/…/prompts/:id` | `archive` | US-009 | 204 | 404/422 |
| POST | `/…/prompts/:id/publish` | `publish` | US-010/048/049 | 201 `{version,status:"published"}` | 200 noop; 422 |
| GET | `/…/prompts/:id/current-version` | `current_version` | US-011 | 200 `{version}` | 404; **409** not-published |
| POST | `/…/prompts/:id/sandbox` | `sandbox` | US-114 | 200 `{rendered,tool_names,mode,note}` | 422; 404 |
| PATCH | `/…/scripts/:id/nodes/:node_id/prompt` | `ScriptController.attach_prompt` | US-011 | — | **M2** (stub) |

**Request bodies**

- `create` / `update`: `{"prompt": {"name", "description"?, "slug"?}}`. `create` merges
  `organization_id` + `created_by_user_id` server-side. Missing `prompt` key → `400`.
- `publish`: `{"version": {"body", "template_vars"?, "tool_defs"?, "metadata"?}}`;
  `published_by_user_id` injected server-side. Missing `version` key → `400`.
- `sandbox`: `{"version": null | "current" | "<version_id>", "sandbox": {"body","template_vars"?,
  "tool_defs"?}, "bindings": {…}}`. `null` → render the submitted draft; `"current"` → resolve the
  head's current published version; a version id → that version (org-checked).

**Response semantics**

- `publish` → **201** `{version, status:"published"}` on new; **200** `{version, status:"noop",
  note}` when an identical-checksum version already exists (idempotent); **422**
  `{error, undeclared_vars:[…]}` when body references undeclared vars; **422** `{error:"invalid
  tool_defs", reason}` on bad tool schema.
- `current_version` → **409** `{error}` when the prompt has no published version ("publish before
  pinning") — distinct from **404** (no such prompt). This is the "attempting to pin an un-published
  prompt is rejected" AC (US-011).
- `version` JSON exposes `checksum` as lowercase hex (`Base.encode16/2`); `index` rows carry
  `usage_count`.
- `index` query params: `q` (name/description substring, case-insensitive), `include_archived`,
  `only_published` (truthy = `true|"true"|"1"|1`). Archived prompts hidden by default.

---

## 5. UI surface

Screens: `project-management/screens/04-prompt-library.md`, `05-prompt-detail.md`.
Components: `19-prompt-body-editor`, `20-variable-declarations-sidebar`, `21-json-schema-editor`,
`22-testing-sandbox`, `05-version-history-panel`, `06-publish-button`, `04-typeahead-selector`.

### 5.1 Prompt Library (`/prompts`) — US-009, US-050

- Table: name, description, status (draft = no `current_version_id`; published otherwise), usage
  count, last-published. New Prompt button. Typeahead search (`q`) over name+description; tag/label
  filter (reads `metadata`). "Use this prompt" returns to the originating graph node editor with the
  prompt attached (deep-link contract into M2 editor; no-op target acceptable in M1).

### 5.2 Prompt Detail (`/prompts/:id`) — US-009/010/011/048/049/114/115

- **Body editor** (`prompt-body-editor`): `{{var}}` + `{% for %}`/`{% if %}` syntax highlight,
  autocomplete on `{{`, inline undeclared-var warning, preview toggle (renders via sandbox).
- **Variable declarations sidebar** (`variable-declarations-sidebar`): per var name, description,
  default, required flag → serialized into `template_vars` on publish (US-048).
- **Tool/function schema editor** (`json-schema-editor`): visual/raw JSON toggle producing canonical
  `tool_defs` (US-049).
- **Publish button** + **version history panel**: published versions with timestamp, publisher,
  checksum; published versions render read-only (US-010).
- **Testing sandbox pane** (`testing-sandbox`, `mode: prompt-test`): variable-binding inputs + agent
  picker + Send. **M1 = render-only**: shows substituted body + declared tool names + the
  "LLM execution deferred to Stage 4" note. Agent picker and latency/token/history are visible-but-
  inert until adapters land (US-114 boundary).

---

## 6. Non-functional requirements

| ID | Requirement | Target |
|---|---|---|
| NFR-1 | New-code line coverage | ≥ 80% (Liquibase schema applied in test harness) |
| NFR-2 | Publish transaction | atomic: version insert + head advance in one `Ecto.Multi`; failure rolls back both |
| NFR-3 | Version immutability | no update path mutates a published `prompt_versions` row |
| NFR-4 | Idempotent publish | identical canonical content ⇒ single row, `status:"noop"`, no version bump |
| NFR-5 | Deterministic render | same `(body, template_vars, bindings)` ⇒ byte-identical output |
| NFR-6 | Tenancy | every query org-scoped; no cross-org read/pin; version `pinnable?` org-checked |
| NFR-7 | Authz least-privilege | reads `viewer`, writes `editor`; 403/404 do not leak membership |

---

## 7. Acceptance criteria (Given/When/Then, per story)

### US-009 — Create a standalone prompt (P0)
- **G** an editor in org O **W** `POST /…/prompts {prompt:{name:"Greeting"}}` **T** 201; slug
  auto-derives to `greeting`, unique within O.
- **G** name omitted **W** create **T** 422 `{errors}` (`name` required).
- **G** a slug already used in O **W** create with that slug **T** 422 (unique-constraint on
  `prompts_organization_id_slug_index`).
- **G** a viewer (not editor) **W** create **T** 403.
- **G** archived prompts exist **W** `GET /…/prompts` without `include_archived` **T** they are
  absent; with `include_archived=1` they appear.

### US-010 — Publish a new prompt version (P0)
- **G** prompt with no versions **W** `POST /…/prompts/:id/publish {version:{body:"hi"}}` **T** 201,
  `version_number=1`, head `current_version_id` advances, `checksum` recorded (hex in payload).
- **G** a published version with body B **W** publish identical B again **T** 200 `status:"noop"`,
  **no** new row, no version bump.
- **G** two sequential distinct publishes **T** `version_number` = 1 then 2 (monotonic).
- **G** any published version **W** read via `show` **T** it is returned read-only (no mutate route).

### US-011 — Reference a published prompt from a script node (P0, **schema stub**)
- **G** a published prompt **W** `GET /…/prompts/:id/current-version` **T** 200 with the exact
  version to pin.
- **G** an unpublished prompt (`current_version_id` nil) **W** current-version **T** **409**
  ("publish before pinning") — attempting to pin is rejected.
- **G** a version id + org **W** `Prompts.pinnable?(org, vid)` **T** true iff the version exists in
  that org; false cross-org.
- **Boundary:** node-side attach (`script_nodes.prompt_version_id`, "update to latest", run-time
  body display) is **M2** — not asserted here beyond resolver/pinnable correctness.

### US-048 — Template variables (P1)
- **G** body `"Hi {{name}}"` with no declaration **W** publish **T** 422
  `{undeclared_vars:["name"]}`.
- **G** body `"Hi {{name}}"` + `template_vars:{name:{required:true}}` **W** publish **T** 201.
- **G** a declared var never used in the body **W** publish **T** allowed (declared-unused is a
  warning, not an error — `Template.validate/2`).
- **G** the collection var in `{% for x in items %}` **W** validate **T** `items` must be declared;
  loop-local `x` must **not** be required as a declaration.

### US-049 — Tool/function schemas (P1)
- **G** `tool_defs:{tools:[{name:"lookup",description:"d",parameters:{type:"object",…}}]}` **W**
  publish **T** 201; `ToolDefs.tool_names/1` returns `["lookup"]`.
- **G** a tool missing `name` or `description`, or `parameters` not an object **W** publish **T**
  422 `{error:"invalid tool_defs", reason}` identifying the failing tool index.
- **G** empty/absent tools **T** valid (tools optional).
- **Boundary:** structural expectations asserting on captured tool calls depend on `run_steps`
  (M3); M1 delivers the schema + `tool_names/1` seam only.

### US-050 — Browse the prompt library (P1)
- **G** prompts with varying script-node references **W** `GET /…/prompts` **T** each row's
  `usage_count` = distinct `script_nodes` pinning any of its versions (0 when `script_nodes` absent
  pre-M2).
- **G** `q="greet"` **T** case-insensitive substring match over name and description.
- **G** `only_published=1` **T** prompts without a `current_version_id` excluded.

### US-114 — Prompt testing sandbox (P2, **render-only**)
- **G** draft `{body:"Hi {{name}}", template_vars:{name:{}}}` + `bindings:{name:"Ada"}` **W**
  `POST /…/prompts/:id/sandbox {version:null, sandbox:…, bindings:…}` **T** 200
  `{rendered:"Hi Ada", tool_names:[], mode:"render_only", note:…}`.
- **G** `version:"current"` on an unpublished prompt **T** 404.
- **G** a required var with no binding and no default **T** 422 `{missing:[…]}`.
- **Boundary:** no `runs` row is created; live agent call, latency/token capture, and last-5 history
  are **out of scope** until Agents/M2.

### US-115 — Loops & conditionals (P3)
- **G** `"{% for x in items %}{{x}},{% endfor %}"` + `bindings:{items:["a","b"]}` **T** renders
  `"a,b,"` deterministically.
- **G** `"{% if flag %}Y{% endif %}"` with `flag` truthy/falsey **T** emits `"Y"` / `""` (falsey =
  `nil,false,"",[],%{}`).
- **G** nested `for`/`if` **T** matching `endfor`/`endif` resolved with correct nesting depth.
- **G** publish-time validation **T** every loop/conditional collection/condition var must be
  declared (shares `Template.validate/2`).

---

## 8. Out of scope (this milestone)

- Version rollback UI, cross-version diff view (US-010 tails → Wave 2).
- Node-side prompt attach runtime, "update to latest" flow, run-time body rendering, bulk update,
  diff-preview (US-011 tails → M2/Wave 2).
- Run-level variable override, persona-metadata variable binding (US-048 tails → Wave 3).
- Tool-response stubbing/mock registry; live tool execution (US-049 tails → Wave 3; never execute).
- Live LLM sandbox invocation, sandbox budget, multi-turn sandbox, history compare (US-114 tails).
- Cross-org sharing / marketplace, prompt recommendation (US-050 tails → post-MVP).
- Arbitrary macros/function calls in templates (US-115 — permanently out; templates stay
  declarative).

---

## 9. Dependencies & gates

**Entry (from roadmap M1):** M0 exit — migrations live, CI green, auth + org membership working;
OpenAPI spec + rubric DSL frozen. `Organizations.authorize/3` and `Codefresh.Guardian` must be
operational (they are, per router `:authenticated` pipeline).

**Exit (Lane A):** prompt can be created, versioned, published, and listed via UI + API; the
US-011 reference stub (`resolve_current_version/2` + `pinnable?/2`) resolves for the not-yet-built
`script_nodes` fixtures used in the M1 cross-lane integration walkthrough (roadmap §"Cross-lane
integration task").

**Blocking sequence:** US-009 → US-010 → US-011; US-048/049/050/114 depend on US-010; US-115
depends on US-048.

**Hard gate (GAP-1):** `025-prompts.yaml` must land and apply before the TDD suite can run — the
Ecto schemas reference tables the DB does not yet create.

---

## 10. Open questions

| # | Question | Recommended default |
|---|---|---|
| Q1 | `tool_defs`/`metadata` DB default — `'{}'` (code) vs `'[]'` (data-model.md §5.1 for tool_defs)? | Follow **code** (`'{}'`, canonical `%{"tools":[…]}`); correct the data-model note |
| Q2 | `slug`/`name` column type — `citext` (data-model.md) vs `:string` (Ecto schema) with app-side lowercasing? | Use `citext` for slug to back the case-insensitive unique index; keep `name` `text` |
| Q3 | Should `current_version_id` FK be DB-deferrable or nullable-then-set-in-txn? | Nullable + set in the same publish `Multi` (matches `advance_current_version_changeset`) |
| Q4 | `list_prompts/2` usage-count join to `"script_nodes"` before that table exists in M1 test env | Author `025` to tolerate absence, or seed an empty `script_nodes` stub table; confirm with M2 lane |
| Q5 | Sandbox "agent picker" visibility in M1 UI when no adapters exist | Render disabled with the deferral note (US-114 boundary) rather than hiding |

---

## 11. Test plan (feeds TDD Tester — GAP-2)

- **`Codefresh.Prompts` context tests:** create/slug-derivation/uniqueness; `publish_version/2`
  (new/noop/undeclared/invalid-tool-defs, monotonic numbers, head advance); `list_prompts/2`
  (search, archived, only_published, usage_count); `resolve_current_version/2` +
  `pinnable?/2` (published/unpublished/cross-org); `sandbox_render/1`.
- **`Template` tests:** `extract_vars/1` (simple, block, loop-local exclusion); `validate/2`;
  `render/3` (`{{var}}`, defaults, missing-required, `if` truthy table, `for` iteration, nesting).
- **`ToolDefs` tests:** valid/empty/missing-name/missing-description/non-object-parameters;
  `tool_names/1`.
- **`PromptController` tests:** every route × authz (viewer/editor/forbidden/not_a_member) × the
  status codes in §4 (esp. publish 201/200/422 and current-version 200/404/409).
