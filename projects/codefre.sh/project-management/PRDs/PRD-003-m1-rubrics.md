---
id: PRD-003
title: "M1 Lane B — Rubrics (LLM-as-judge scoring primitive)"
status: draft
milestone: M1
lane: "B — Rubrics"
stories: [US-033, US-034, US-056, US-057, US-058, US-119, US-120]
created: 2026-07-22
updated: 2026-07-22
---

# PRD-003: M1 Lane B — Rubrics

**Version**: 1.0
**Status**: Draft (PRD gate for M1 Lane B / impl-plan Stage 2a)
**Author**: npl-prd-editor
**Roadmap ref**: `project-management/roadmap/02-M1-authoring-primitives.md` (Lane B)
**DSL contract**: `docs/arch/rubric-dsl.md` (contract-frozen v1.0.0, 2026-04-20 — this PRD conforms to it)
**Data model**: `docs/arch/data-model.md` §5.5, §6.6, §14.11, §17 addenda
**Backend zone (exclusive)**: `app/backend/lib/codefresh/rubrics/`
**Frontend zone (exclusive)**: rubric list/detail screens in `app/frontend/`

---

## 1. Overview

codefre.sh evaluates AI agent outputs. A **rubric** is the versioned, org-owned
primitive that declares *how* an expectation is scored by an LLM-as-judge: which judge
prompt, which model, what scale, and (optionally) which weighted criteria. This PRD
specifies the Rubrics domain for milestone **M1**: create → edit → publish version →
browse/reuse, in both UI and API, plus render-only preview, marketplace import, and
n-sample confidence configuration.

The rubric body shape is **frozen** by `rubric-dsl.md` v1.0.0. Every requirement below
conforms to that contract; where a user story's wording diverges from the frozen DSL,
the divergence is flagged in §11 (Conflicts) rather than silently resolved.

### Goals

1. A versioned, org-scoped `rubrics` / `rubric_versions` domain with copy-on-write,
   checksum-dedup publish (US-033).
2. Continuous, discrete, ladder, and enum scales (US-057) and weighted multi-criterion
   bodies (US-056), validated against the frozen DSL JSON shape.
3. Render-only rubric preview that never charges the user and never writes a `scores`
   row (US-058, conforming to the frozen `render_only` contract).
4. `n_samples` confidence-band configuration on the rubric body (US-120) and the
   `confidence_band/1` scoring helper — persistence into results is M4.
5. Cross-org marketplace import that deep-copies a rubric into the caller's org (US-119).
6. The `scoring_method='rubric'` / `rubric_version_id` **reference contract** an
   expectation will pin (US-034) — schema/contract stub only in M1.

### Non-Goals

- Executing the judge LLM (live scoring). Preview is render-only in M1; adapter
  dispatch is impl-plan Stage 4+.
- Re-scoring past runs (US-059), cross-version score comparison (US-060), and
  disagreement analytics (US-121) — **owned by M4**. The data model here must not
  preclude them (see §5, §12).
- Per-criterion drill-down in the results view, marketplace publish-back (author side),
  and model-intrinsic (logprob) confidence — all Wave 3+.

---

## 2. Background & current state

- **M0 exit** delivered: migrations live, CI green, auth + org membership working, the
  OpenAPI spec and the rubric DSL JSON-schema frozen.
- `data-model.md` already models `rubrics` (common head), `rubric_versions`
  (`judge_prompt_version_id`, `judge_model`, `scale` jsonb, `criteria` jsonb), the
  `n_samples` addendum (§17, CHECK 1..10), `marketplace_rubrics`, and the `scores`
  table (append-only, pins `rubric_version_id` + `judge_prompt_version_id` +
  `judge_model`). This PRD **implements** those tables; it does not redesign them.
- **Judge prompts** are ordinary `prompts` / `prompt_versions` authored in **Lane A**
  (PRD-002). Rubrics reference a *published* `prompt_version` by id; a rubric cannot
  author its own judge prompt inline (US-033 out-of-scope).
- `expectations` and `script_nodes` **do not exist until M2** — hence US-034 is a
  reference-contract stub here (§4.2).

---

## 3. Requirements per story

### US-033 — Create a simple rubric with LLM-as-judge scoring (P0)

- FR-033.1 `POST /api/v1/rubrics` creates a rubric **head** (`organization_id`, `slug`,
  `name`, optional `description`); `current_version_id` is null until first publish.
- FR-033.2 The create/edit editor selects a **published** `prompt_version` as
  `judge_prompt_version_id` and a `judge_model` string (e.g.
  `anthropic:claude-sonnet-4-5`).
- FR-033.3 `scale` defaults to `{"type":"continuous","min":0,"max":1}`; overridable.
- FR-033.4 `criteria` defaults to `{"items":[]}` (empty is valid — single-judgment rubric).
- FR-033.5 `POST /api/v1/rubrics/:id/versions` publishes an immutable `rubric_versions`
  row: computes `checksum = sha256(canonical(body))`; an identical canonical body under
  the same head returns the existing version as `{:ok, :noop}` (idempotent re-publish).
- FR-033.6 On first successful publish, the head's `current_version_id` is set.

### US-034 — Attach a rubric to an expectation (P0, **schema stub only**)

- FR-034.1 Define and freeze the **reference contract** an expectation pins:
  `expectations.scoring_method='rubric'` ⇒ `rubric_version_id` (FK, required) is set to
  a rubric's **currently published** version id at attach time (pin-at-attach, mirroring
  US-011 prompt referencing).
- FR-034.2 Provide `Rubrics.published_version_id/1` (returns the head's
  `current_version_id` or `{:error, :no_published_version}`) so the M2 expectation editor
  has a stable resolver. No expectation UI/endpoint ships in M1.
- **Boundary (explicit):** the `expectations` table, its `scoring_method` CHECK
  coherence, the rubric picker UI, and the "validation fails if no rubric attached" rule
  are **finalized in M2** when expectations land. M1 delivers only the resolver + the
  documented FK/enum contract so M2 has nothing to renegotiate.

### US-056 — Weighted multi-criterion rubric (P1)

- FR-056.1 Rubric body accepts an ordered `criteria.items[]`, each item
  `{name, weight, direction}` per the frozen DSL, with optional per-item `judge_model`.
- FR-056.2 `weight ∈ [0.0, 1.0]`; weights need not sum to 1.0 —
  `Rubrics.Scoring.weighted_average/2` normalizes by `Σ weights` at score time.
- FR-056.3 `direction ∈ {positive, negative}`; negative criteria invert in the aggregate.
- FR-056.4 Per-criterion `judge_model` override is **accepted and persisted** by the
  changeset now; runner dispatch on the override is Stage 5+ (stub-accepted).
- FR-056.5 Empty `criteria` remains valid (single-judgment rubric).
- **Note (see §11-C):** the DSL item key is `name`; the story/screen say
  `label` + `description`. This PRD adopts DSL `name` as canonical and treats
  `description` as an optional non-canonical UI field stored under item metadata,
  **excluded from the checksum**.

### US-057 — Ladder / enum scoring scale (P1)

- FR-057.1 `scale.type` accepts `ladder` and `enum` (in addition to `continuous`,
  `discrete`), each with `values: [{label, score}, …]`.
- FR-057.2 Ladder/enum values must be **non-empty** and have **non-decreasing** scores
  (monotonic); non-monotonic mappings are rejected.
- FR-057.3 `enum` and `ladder` share the shape; the semantic distinction (`enum`
  unordered e.g. pass/warn/fail, `ladder` strictly ordered) is preserved in `scale.type`.
- FR-057.4 `Rubrics.Scoring.score_for_label/2` maps a returned label → numeric for
  aggregation; the label is retained for display (Results UI shows label prominently — M4).

### US-058 — Preview a rubric by scoring a sample response (P1, **render-only in M1**)

- FR-058.1 `POST /api/v1/rubrics/:id/preview` (and draft-body variant) calls
  `Rubrics.preview_render/3` over `{sample_input, sample_response}` and the current draft
  body. It **renders** the judge prompt; it does **not** invoke the LLM.
- FR-058.2 Response returns `{judge_model, scale, criteria, n_samples,
  rendered_judge_prompt, estimated_tokens, mode:"render_only"}`.
- FR-058.3 `estimated_tokens` is approximate (token count of the rendered prompt); the UI
  shows the estimated cost **before** any future invocation. The preview **never charges**
  the user and **never writes a `scores` row** (out-of-band, un-audited).
- **LLM-as-judge invocation contract (spec for Stage 4, not shipped in M1):** when live
  preview lands, the invocation MUST — (a) source model config from the *draft* rubric
  body's `judge_model` (per-criterion overrides honored); (b) enforce a per-call timeout
  (default 30s, configurable) and surface `:timeout` as a recoverable preview error;
  (c) attribute cost as **preview/out-of-band** — never billed against a run, never
  producing a `scores` row; (d) return overall score, per-criterion sub-scores, and judge
  rationale. See §11-A: the story AC ("see how the judge scores it") is **deferred** to
  this contract; M1 ships FR-058.1–3 only.

### US-119 — Import a rubric from a shared marketplace (P2)

- FR-119.1 `GET /api/v1/marketplace/rubrics` browses curated rubrics, filterable by
  `domain ∈ {safety, rag, code_generation, summarization, other}` and provenance;
  ordered by `(curation_status, published_at DESC)`.
- FR-119.2 `GET /api/v1/marketplace/rubrics/:id` returns criteria, judge model, author
  org, and a canned sample scoring for display.
- FR-119.3 `POST /api/v1/marketplace/rubrics/:id/import` **deep-copies** the
  `rubric_version` body (not an id reference) into the caller's org as a fresh head +
  version; stores `metadata.imported_from` provenance in the new version row;
  increments `marketplace_rubrics.download_count`.
- FR-119.4 If the source `judge_prompt_version_id` is not pinnable in the importer's org,
  import fails explicitly with `:judge_prompt_requires_local_copy` (UI: "copy the judge
  prompt first, then retry").
- Publishing back to the marketplace (author side) is out of scope (Wave 3+).

### US-120 — Rubric confidence bands (P2)

- FR-120.1 Rubric body accepts `n_samples ∈ [1, 10]` (default 1, `stddev` 0.0 at n=1).
- FR-120.2 `Rubrics.Scoring.confidence_band/1` computes `%{mean, stddev, low, high}`
  (±1σ default; wider intervals configurable per call).
- FR-120.3 The changeset warns (non-blocking) that cost scales linearly and the runner
  must warn before triggering `n > 3` runs.
- **Boundary:** persisting the interval into `scores.raw_output.confidence_interval` and
  rendering "0.82 ± 0.04" in the Results UI require the **results layer (M4)**. M1
  delivers the `n_samples` config + validation + `confidence_band/1` helper only.

---

## 4. Data model

Implements `data-model.md` §5.5 / §14.11 / §17 addenda. **No schema redesign.**

### 4.1 `rubrics` / `rubric_versions`

- `rubrics` — common head shape (`id`, `organization_id`, `slug` citext, `name`,
  `description`, `current_version_id` nullable, `archived_at`, `created_by_user_id`,
  timestamps). `UNIQUE (organization_id, slug)`.
- `rubric_versions` — common version shape (`id`, `rubric_id` FK, `organization_id`
  denormalized, `version_number`, `checksum bytea`, `published_by_user_id`,
  `inserted_at`; **no `updated_at` — immutable, append-only**) plus:
  `judge_prompt_version_id` (FK `prompt_versions`, nullable), `judge_model` text,
  `scale` jsonb (not null), `criteria` jsonb (not null), `n_samples` integer default 1
  (CHECK 1..10), and `metadata` jsonb (holds `imported_from`, non-canonical UI fields).
- Constraints: `UNIQUE (rubric_id, version_number)`, `UNIQUE (rubric_id, checksum)`.
- **Canonical body / checksum:** `checksum = sha256(canonical(judge_prompt_version_id,
  judge_model, scale, criteria, n_samples))`. `criteria.items[].description` and other
  UI-only fields under `metadata` are **excluded** from the canonical body.

### 4.2 Reference contract (US-034 stub)

- `expectations.scoring_method` enum includes `:rubric`; `expectations.rubric_version_id`
  (FK, required iff `scoring_method='rubric'`) — **documented here, created in M2.**
- `scores` (M4) pins `(rubric_version_id, judge_prompt_version_id, judge_model)` — M1
  must not alter the frozen `scores` shape; re-scoring mints new rows (M4).

### 4.3 `marketplace_rubrics`

Per §14.11: `rubric_version_id` FK cascade, `author_organization_id` FK restrict,
`title`, `description`, `published_at`, `download_count`, `average_rating` (no rating UI
in MVP), `curation_status` enum, `domain` enum. Indexes
`(domain, curation_status, published_at DESC)`, `(author_organization_id)`.

---

## 5. API surface

All routes org-scoped and PBAC-gated (§8). JSON. Errors as `{errors: [{code, detail}]}`.

| Method & path | Purpose | Story | Min role |
|---|---|---|---|
| `GET /api/v1/rubrics` | list org rubrics (heads + current version summary) | US-033 | viewer |
| `POST /api/v1/rubrics` | create head (+ optional first draft body) | US-033 | editor |
| `GET /api/v1/rubrics/:id` | head + version history | US-033 | viewer |
| `PATCH /api/v1/rubrics/:id` | update head name/description | US-033 | editor |
| `POST /api/v1/rubrics/:id/archive` | soft-archive head (`archived_at`) | US-033 | editor |
| `POST /api/v1/rubrics/:id/versions` | publish immutable version (checksum-dedup) | US-033/056/057/120 | editor |
| `GET /api/v1/rubrics/:id/versions/:n` | fetch a pinned version body | US-033 | viewer |
| `POST /api/v1/rubrics/:id/preview` | render-only preview of a draft body | US-058 | viewer |
| `GET /api/v1/marketplace/rubrics` | browse curated (filter `domain`, provenance) | US-119 | viewer |
| `GET /api/v1/marketplace/rubrics/:id` | marketplace detail + canned sample | US-119 | viewer |
| `POST /api/v1/marketplace/rubrics/:id/import` | deep-copy into caller org | US-119 | editor |

**Publish/version semantics:** version tables are append-only; there is no draft *row*.
A "draft" is the in-editor unsaved body; it persists only on publish. Publish validates
the body against the DSL (§6), computes the checksum, and either inserts a new
`rubric_versions` (incrementing `version_number`, updating head `current_version_id`) or
returns the existing version on a checksum match (`{:ok, :noop}`, HTTP 200 with a
`deduplicated: true` flag).

---

## 6. DSL validation rules (publish + preview)

Enforced in `RubricVersion` changeset / `Rubrics.Scoring`, mirroring
`rubric-dsl.md` §"Validation rules":

| Rule | Location | Error code |
|---|---|---|
| `scale.type ∈ {continuous, discrete, ladder, enum}` | `validate_scale/1` | `:invalid_scale_type` |
| continuous/discrete: `max > min`, both numeric | `validate_numeric_scale/2` | `:invalid_numeric_scale` |
| ladder/enum: non-empty `values`, each `{label, score}`, non-decreasing scores | `validate_enum_scale/2` | `:invalid_enum_scale` |
| criteria: each `{name, weight ∈ [0,1]}`; empty map OK | `validate_criteria/1` | `:invalid_criteria` |
| `n_samples ∈ [1, 10]` | `validate_number/3` | `:invalid_n_samples` |
| `judge_prompt_version_id` pinnable within org | `Rubrics.publish_version/2` | `:judge_prompt_not_pinnable` |

Any change to canonical checksum computation is a **breaking** DSL change (bump DSL
version + migration note) — out of scope here.

---

## 7. UI surface

Screens (exclusive to this lane): `11-rubric-list`, `12-rubric-detail`,
`35-rubric-marketplace`. Component: `12-score-panel` (Expanded variant, render-only
in M1). Re-score / score-comparison affordances on `12-rubric-detail` and screen
`31-rubric-score-comparison` are **M4** — omit or disable in M1.

- **Rubric list** — org rubrics, published/draft state, current version, "New rubric".
- **Rubric detail (editor)** — judge-prompt picker, judge-model selector, scale editor
  (continuous/discrete/ladder/enum), criteria list (name, weight, direction, optional
  model override), `n_samples` control, preview pane (sample input/response + "Score
  now" → render-only in M1, shows `rendered_judge_prompt` + `estimated_tokens`), publish
  button, version history (version number, checksum, timestamp).
- **Marketplace** — browse by domain/provenance, detail with canned sample, "Import"
  (surfaces `:judge_prompt_requires_local_copy` guidance).

---

## 8. Non-functional requirements

| ID | Requirement | Target |
|---|---|---|
| NFR-1 | Test coverage for new `rubrics/` code | ≥ 80% line |
| NFR-2 | Publish (validate + checksum + insert) latency | < 150ms p95 (excl. LLM) |
| NFR-3 | Preview render (no LLM) | < 200ms p95 |
| NFR-4 | Org isolation | every query filters `organization_id`; no cross-org read/write except marketplace import |
| NFR-5 | PBAC | viewer read; editor/admin/owner write; enforced at controller + context |
| NFR-6 | Immutability | version rows never UPDATE/DELETE (convention now; REVOKE/trigger tracked in data-model §17) |
| NFR-7 | Preview cost safety | preview never bills, never writes `scores` |

---

## 9. Acceptance criteria (Given/When/Then, TDD-ready)

**US-033** — *G* an org editor with a published judge prompt; *W* they POST a rubric
then POST a version with `{judge_prompt_version_id, judge_model, scale:default,
criteria:{items:[]}}`; *T* a `rubric_versions` row is created with a sha256 checksum and
the head's `current_version_id` is set. *G* the same body re-published; *W* POST versions
again; *T* returns `{:ok, :noop}` (HTTP 200, `deduplicated:true`), no new row.

**US-034** — *G* a rubric with a published version; *W* `Rubrics.published_version_id/1`
is called; *T* it returns that version id. *G* a rubric with no published version; *W*
called; *T* returns `{:error, :no_published_version}`. (No expectation endpoint asserted
— M2 boundary.)

**US-056** — *G* a body with `criteria.items` = accuracy 0.6 (positive), safety 0.1
(negative); *W* published; *T* accepted, checksum stable across item reordering only if
canonicalization sorts deterministically (assert canonical form). *G* an item with
`weight:1.4`; *W* published; *T* rejected `:invalid_criteria`. *G* two positives 0.6/0.3;
*W* `weighted_average([0.8,0.4])` scored; *T* normalized by Σweights (0.9).

**US-057** — *G* `scale:{type:"ladder", values:[{label:"poor",score:0.0},
{label:"excellent",score:1.0}]}`; *W* published; *T* accepted. *G* ladder with scores
`[1.0, 0.5]` (decreasing); *W* published; *T* rejected `:invalid_enum_scale`. *G* label
`"excellent"`; *W* `score_for_label/2`; *T* returns `1.0`.

**US-058** — *G* a draft body + `{sample_input, sample_response}`; *W* POST preview;
*T* response has `mode:"render_only"`, a non-empty `rendered_judge_prompt`, an
`estimated_tokens` integer, and **no** `scores` row is created; the LLM is never invoked
(assert judge adapter not called).

**US-119** — *G* a curated marketplace rubric whose judge prompt is pinnable in my org;
*W* POST import; *T* a new head + version exist in my org with `metadata.imported_from`
set and `download_count` incremented. *G* a rubric whose judge prompt is not pinnable;
*W* import; *T* fails `:judge_prompt_requires_local_copy`, no rows created.

**US-120** — *G* body `n_samples:5`; *W* published; *T* accepted. *G* `n_samples:11`;
*W* published; *T* rejected `:invalid_n_samples`. *G* samples `[0.8,0.82,0.78,0.81,0.79]`;
*W* `confidence_band/1`; *T* returns `%{mean, stddev, low, high}` with `low = mean-stddev`,
`high = mean+stddev`. *G* `n_samples:1`; *T* `stddev == 0.0`.

---

## 10. Out of scope (owned elsewhere)

- **M4 (results layer):** US-059 re-scoring, US-060 cross-version comparison, US-121
  disagreement analytics; persisting confidence intervals into `scores.raw_output`;
  Results-UI score display, ± rendering, and screen `31-rubric-score-comparison`.
  *The M1 data model does not preclude them — `scores` shape is untouched and re-scoring
  mints new rows.*
- **Stage 4+:** live LLM judge invocation (preview or run), per-criterion model-override
  dispatch, model-intrinsic (logprob) confidence.
- **M2:** the `expectations` table, rubric-picker UI, attach validation (US-034 body).
- **Wave 3+:** marketplace publish-back, criteria inheritance, adaptive weights, batch
  preview, rating UI, mixed ladder+continuous criteria.

---

## 11. Conflicts found (flagged, not silently resolved)

- **11-A · US-058 preview: story vs frozen DSL (MATERIAL).** US-058 AC says "see how the
  judge scores it" / "Results show overall score, per-criterion scores, judge rationale"
  and "cost shown before invocation" — i.e. a **live** judge call. The **frozen** DSL
  (`rubric-dsl.md` §Preview) defines `preview_render/3` as **`render_only`**, LLM
  execution "deferred to Stage 4". PRD conforms to the frozen contract: M1 ships
  render-only (FR-058.1–3) and **specs** the invocation contract for Stage 4 (§US-058).
  **Needs a ruling:** accept render-only-in-M1 (recommended, matches roadmap Stage 4), or
  pull live preview forward (would require an adapter dependency M1 does not have).
- **11-B · US-058 roadmap vs DSL wording.** The roadmap exit criteria say "Rubric preview
  scoring (US-058) works against a sample response with LLM-as-judge" — which reads as
  live. This contradicts the frozen DSL's render-only. Same ruling as 11-A resolves both;
  flagging because the roadmap line may need an edit to "render-only preview" for M1.
- **11-C · US-056 / screen-12 criterion keys vs DSL.** Story US-056 and screen
  `12-rubric-detail` describe criteria as `{label, description, weight, model override}`;
  the frozen DSL uses `{name, weight, direction, judge_model}` with **no** `label`/
  `description` and an extra `direction`. PRD adopts DSL `name`/`direction` as canonical;
  `description` becomes a non-canonical UI field (metadata, excluded from checksum).
  **Confirm** `direction` is surfaced in the editor (stories never mention it).
- **11-D · US-057 discrete scale.** The DSL defines a `discrete` scale type; no story
  explicitly requests it (US-057 covers ladder/enum, US-033 continuous). Included in
  validation for DSL conformance; flagging that no story drives a `discrete`-specific UI
  affordance in M1.
- **11-E · US-120 persistence target.** US-120 AC names
  `scores.raw_output.confidence_interval` and Results-UI rendering, both of which live in
  the **M4** results layer. M1 delivers config + helper only; the AC's persistence/UI
  clauses are satisfied in M4 (noted in §3 boundary, not a contradiction — a phase split).

---

## 12. Dependencies & gates

- **Upstream (blocking):** Lane A prompts (PRD-002) — a rubric needs a published
  `prompt_version` to reference as its judge prompt. M0 migrations + auth + org
  membership. Frozen DSL + OpenAPI (M0 Lane B) — done.
- **Downstream:** M2 expectations consume the US-034 reference contract; M4 results
  layer consumes `rubric_versions` + `n_samples` + `confidence_band/1`.
- **Gate (M1 exit for this lane):** a rubric can be created, versioned, published, and
  listed via UI and API; render-only preview works against a sample; the cross-lane
  integration walkthrough resolves `rubric-id` from a script-node fixture (§roadmap
  "Cross-lane integration task").

---

## 13. Open questions

- [ ] Q1 (11-A/B): confirm render-only preview for M1, and edit the roadmap exit line
      accordingly?
- [ ] Q2 (11-C): expose `direction` (positive/negative) in the criteria editor in M1, or
      default all to `positive` and defer the toggle?
- [ ] Q3: does creating a rubric head with an inline first body publish immediately, or
      is the first version always an explicit second call? (PRD assumes explicit publish;
      head create may accept an optional draft body that is *not* persisted until publish.)
- [ ] Q4: marketplace seed — is the M1 marketplace a curator-edited starter pack only
      (no author publish path), per US-119 note? (PRD assumes yes.)
