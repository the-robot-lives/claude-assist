# MCP Description Tailoring, Packaging & Overview — Design Spec

Status: DRAFT for review · Session: `2fb48a80-7278-4b88-aa8a-bbae6773cdd8` · 2026-07-16

Covers five features across `libs/elixir-mcp` (`Noizu.MCP.*`) and the tobor.locker backend
(`NoizuPromptLingua.*`):

1. Composite packaging: **all-in-one** vs **core+custom**, required-core protection
2. **Verbosity-leveled** descriptions (tools, args, fields) with gap-fill interpolation
3. **Per-runner/model tagged** descriptions + session `runner`/`model`
4. Inline **`@eval`** annotations for description tuning
5. **`mcp_overview`** tool — task-proximity, pgvector-backed tailored overviews

---

## 0. Shared concept: the description resolution pipeline

Today a tool has exactly one `description` string, rendered in one place
(`Noizu.MCP.Types.Tool.to_map/1`; field descriptions via `Fields.to_json_schema/1`;
app-side projection in `NoizuPromptLingua.Tools.Catalog.build/2`).

All of features 2–5 hang off one new concept: descriptions become **variant sets**, and every
render site takes a **render context**:

```elixir
%Noizu.MCP.RenderCtx{
  verbosity: 0..9 | nil,      # nil ⇒ resolve via defaults chain
  runner:    atom | nil,      # e.g. :codex, :grok, :claude
  model:     atom | String.t | nil,  # e.g. :"5.4", "ultra-spark-2"
  defaults:  %{verbosity: 5}, # merged: annotation < server < deployment/global
}
```

**Selection precedence** (first match wins):

1. `@runner` rule whose `{provider, model}` matcher fits ctx — specificity order:
   exact model > model-in-list > `:*` wildcard; provider exact > `:*`.
   Within the matched rule, its own `verbosity → tag` map applies (same gap-fill rules),
   falling back to the rule's `default:` tag.
2. Tool/field-level `verbosity → variant` entries, gap-filled (§2).
3. The plain/definitive string (a bare `description: "text"` — or `default:` entry).

**Effective verbosity precedence**: explicit per-call arg (discovery tools accept
`verbosity`) > session/scope config > annotation `default: [{:verbosity, N}]` > server-level
global > deployment/project global (for composite endpoints) > built-in `5`.

Backwards compatible: a plain string is the definitive version at every level unless explicit
overrides exist, in which case it acts as the `default:` fallback.

---

## 1. Packaging: all-in-one vs core+custom

### Current state

- `NoizuPromptLingua.MCPServers` — static `@servers` catalog (24 groups, `required` flag),
  `for_host/1` renders per-subdomain URLs + `custom:<slug>` scopes.
- `mcp_custom_scopes` table (`slug, name, description, config`) — admin-managed global presets;
  `MCP.Custom` serves `config.groups`-selected tools + discovery at `/custom/:slug/mcp`.
- `GET /auth/mcp/config` returns the full server list for client registration.

### Changes

**Scope kinds.** `mcp_custom_scopes` gains `kind` (`"custom" | "all_in_one" | "core_variant"`)
and optional `organization_id` / `project_id` associations (scopes become attachable to
org/project, not only global presets).

- `all_in_one`: one composite endpoint carrying *everything the project needs* — core groups
  + project groups + optional task-segmented one-off sections. No standalone
  sessions/orgs/projects endpoints required in the registration output.
- `core_variant`: a named core package (itself a custom MCP endpoint) containing the core
  grip: **sessions, projects, npl loader** (+ orgs). Multiple variants allowed with terser
  sections, e.g. `core`, `core-terse` (a variant may pin a lower default verbosity — §2).

**Required-core protection (new concept).** Groups already flagged `required` in `@servers`
are auto-included and marked `required` inside any `all_in_one` scope config. Users may still
disable one, but only via a **double-step typed confirmation**:

- API: `PATCH` on scope config that sets `disabled: true` on a required group is rejected
  unless the payload includes `confirm: "YES I KNOW WHAT I AM DOING"` (exact string; proposal —
  configurable constant). Audit fields `disabled_confirmed_by` / `_at` recorded in the group
  config entry.
- UI: two-step — toggle prompts a text input requiring the phrase verbatim.
- Applies only where the scope is `all_in_one` (a deliberate everything-included package);
  plain `custom` scopes keep today's free-form enable/disable.

**Registration/auth-string packaging.** `GET /auth/mcp/config` gains `packaging` param:

- `packaging=core+custom` → returns: chosen core variant endpoint (`/custom/core/mcp` or
  `core.<host>`) + the project's custom scope endpoint.
- `packaging=all_in_one` → returns the single all-in-one endpoint (+ any segmented one-off
  scopes the project defines for special tasks).
- default (unset) → current behavior, unchanged.

The mcp-keys UI offers the packaging choice when generating auth strings / `claude mcp add`
snippets.

---

## 2. Verbosity-leveled descriptions

### DSL

Anywhere a description string is accepted today (tool `description:`, toolkit `@mcp`
`description:`, `field ... description:`, output fields), a variant list is now also accepted:

```elixir
use Noizu.MCP.Server.Tool,
  description: [
    {{:verbosity, {2, 3}}, "Medium description."},
    {{:verbosity, 0},      "Terse."},
    default: "Definitive fallback text"
  ]
# or, unchanged:
use Noizu.MCP.Server.Tool, description: "just text"
```

Keys: `{:verbosity, n}`, `{:verbosity, {lo, hi}}` (inclusive range), `{:verbosity, [n, ...]}`
(explicit set), `default:`. Verbosity domain: **0–9** (0 = tersest). Default default = **5**,
overridable via `default: [{:verbosity, 3}]` in the annotation, a server-level global, or a
deployment/project global for composite endpoints.

### Gap-fill (uncovered levels)

For requested level `v` with no covering entry: use the entry whose nearest covered level has
minimum distance to `v`; **on tie, prefer the lower level** ("left preference").

Worked examples (from requirements):

- Defined `{2,3}` and `0`, request `1` → distance 1 to both `0` and `2` → tie → **0**.
- Defined `3` and `9` only: `8` → **9** (1 < 5); `5` → **3** (2 < 4); `6` → tie (3,3) → **3**.

A bare string covers all levels. Explicit entries always beat gap-fill.

### Render plumbing

- `Types.Tool.description` becomes `String.t | Noizu.MCP.Description.t` (a normalized variant
  struct compiled at `@before_compile`); `to_map/2` takes `RenderCtx`.
- `Fields.to_json_schema/2` and `apply_common_opts/3` take ctx.
- `Features.Tools` passes ctx from conn assigns into `tools/list` rendering; `Catalog.build/3`
  likewise. Existing call sites default to `RenderCtx.default/0` — zero behavior change for
  single-string tools.
- Discovery tools (`ToolSummary`, `ToolDefinition`, `ToolHelp`) gain optional `verbosity` arg.
- **Gap-spin tooling**: `mix noizu.mcp.describe --fill` proposes LLM-interpolated variants for
  uncovered levels ("custom spin in the continuum"), written back as code suggestions for
  review — never auto-applied. Pairs with `@eval` (§4) for quality gating.

---

## 3. Per-runner/model tagged descriptions + session runner/model

Motivation: work around weak harnesses/models with tailored wording, without forking tools.

### DSL — named variants + selection rules

```elixir
@descriptions [foo_bar: "text …", "hippo-5": "text …", codex_foobar: "text …"]

@verbosity_map [{{0, 5}, :foo_bar}]                 # verbosity range → named variant

@runner {:grok, :*}, [{{:verbosity, {0, 5}}, :"hippo-5"}]
@runner {:codex, [:spark, :"5.4"]}, [default: :codex_foobar]
```

(Toolkit `@mcp` and Tool `use` options get equivalent keys: `descriptions:`, `verbosity_map:`,
`runners:`.) Matchers: `{provider, model}` with `:*`, exact atom/string, or list membership.
Resolution follows §0 precedence; runner rules' verbosity maps use §2 gap-fill.

### Session carries runner/model

- `Session.Create` gains optional `model` and `runner` fields (e.g. `runner: "codex"`,
  `model: "5.4"`); session entity + `sessions` table + Liquibase changelog updated;
  `Session.Update` allows changing them (they change dynamically mid-session).
- Subsequent calls: discovery tools accept optional `session`, `runner`, `model` args;
  when present they override the session-stored values for that call. The custom gateway also
  honors `X-MCP-Runner` / `X-MCP-Model` headers into assigns → `RenderCtx`.

---

## 4. Inline `@eval` annotations

Attach evals to a tool for continuous description-quality tuning across model × verbosity
permutations:

```elixir
@eval name: :simple_task,
      prompt: [...],                    # messages driving a model to use the tool
      rubric: [
        fresh: "includes post-training-cutoff knowledge-base entries for API version changes",
        covers_pitfall: "resulting call includes {x, y, z}; notes what to avoid"
      ]
```

- Compiled into `Spec` metadata; never on the wire.
- Harness: `mix noizu.mcp.eval [--tool T] [--runner R --model M] [--verbosity N|all]` renders
  the tool schema through the resolution pipeline for each permutation, runs the prompt against
  the target model, LLM-judge grades each rubric criterion, persists scores
  (`mcp_description_evals` table) → regression gate when tuning descriptions (§2/§3) so terser
  or model-specific variants don't silently degrade call quality.

---

## 5. `mcp_overview` — task-proximity tailored overviews

New hidden tool auto-registered on every composite/custom endpoint (like the discovery block):

`mcp_overview(task: string, focus: optional string, verbosity: optional int)`
— "what the agent is working on" in, tailored overview of the endpoint's available tools out.

Flow:

1. Embed `task` (existing OpenAI 1536-d embedding path, `Domains.Memory.Embeddings`).
2. Nearest-neighbor search in **postgres/pgvector** table `mcp_overviews`
   (`id, scope_slug, task_text, task_embedding vector(1536), overview_md, runner, model,
   verbosity, status: generated|approved|rejected, inserted_at, …`), filtered by scope and
   (when set) runner/model, preferring `approved`.
3. Within threshold → return cached overview.
4. Miss → LLM generates an overview from `Catalog.specs/2` for that scope, **focused by
   proximity**: per-group/per-tool description embeddings (a `mcp_tool_vectors` table over
   description permutations) are ranked against the task vector to decide which sub-items get
   depth vs a one-liner. Stored as `generated` (pending review), returned flagged
   `"generated": true`.
5. Review loop: admin UI lists `generated` overviews for approve/edit/reject — approved entries
   become the durable recall set.

Also closes the `ToolSearch :intent` stub: same embedding path, ranking tool vectors by task
proximity, scoped to the endpoint.

> **Divergence, per explicit instruction 2026-07-16**: vectors here go to **postgres
> (pgvector), not Weaviate**, unlike `Domains.Memory.VectorStore`/mock-MCP (and contra the
> "no pgvector" notes in changelogs 046/048). Infra prerequisite: `CREATE EXTENSION vector`
> in `tobor_locker` DB — confirm the deployed postgres image ships pgvector before the
> changelog lands.

---

## Implementation order

1. **Lib: variant descriptions + RenderCtx + gap-fill** (`tool.ex`, `toolkit.ex`, `fields.ex`,
   `types/tool.ex`, `features/tools.ex`) — foundation; strictly additive.
2. **Runner/model rules + session fields** (lib resolution + `session_create/update`,
   entity/schema, Liquibase, discovery-arg threading).
3. **Packaging** (scope `kind`, required-core confirm flow, `for_host/2` packaging,
   `auth_controller.mcp_config`, mcp-keys UI).
4. **`@eval` + eval harness** (metadata + mix task + eval table).
5. **`mcp_overview`** (pgvector changelogs, embedding/cache module, tool, review UI,
   `ToolSearch :intent`).

## Implementation addendum (2026-07-16, same session — all landed, uncommitted, verified)

All five sections implemented; lib suite 433 green (two seeds), backend feature suites 44 green,
Liquibase 071/072/073 genuinely applied against a pgvector pg16 instance. Deviations made
during implementation, for review:

- **§2**: `default:` keeps meaning fallback *text*; annotation-level default verbosity is the
  separate `default_verbosity:` key (the spec'd `default: [{:verbosity, 3}]` form was ambiguous
  against `default: "text"` and is NOT accepted). `title:` also supports variant form.
- **§3**: matcher specificity — **model outranks provider** (exact-model/wildcard-provider
  beats exact-provider/wildcard-model); documented in `Noizu.MCP.Description` moduledoc.
- **§1**: required core resolved to `["sessions", "organizations"]`; there is **no standalone
  `npl` group** (NPL loader lives only on the root endpoint), so the seeded "core" variant is
  sessions/projects/organizations — making npl a selectable group is a follow-up. Core-variant
  seeding is code-level get-or-create (`mcp_custom_scopes` is Ecto-created; 071 carries a
  tableExists precondition).
- **§4**: eval score persistence (`mcp_description_evals`) deferred to backend; lib ships
  behaviours + deterministic stubs only.
- **§5**: recall filters scope+status only for now (runner/model stored for provenance);
  per-runner recall layers in once ctx threading lands. Indexer refresh is lazy (miss-driven).
- **Ops**: `databasechangelog` stores bare filenames — run liquibase with
  `--search-path=<dir> --changeLogFile=db.changelog-master.yaml`, never a dir-prefixed
  changeLogFile, or previously-run detection breaks.
- **Pending decisions**: backend still consumes `noizu_mcp` 0.1.3 from hex — RenderCtx
  threading (custom gateway, `Catalog.build/2`, discovery args) is specced (§3) but waits on
  hex publish of 0.1.4 vs path override (path breaks the backend Docker build context).

## Open questions

1. Verbosity domain 0–9 confirmed? (Examples used 0–5 plus a 9.)
2. Scope ownership: OK to add org/project association to `mcp_custom_scopes` (global presets
   still supported), so project all-in-ones are self-service rather than admin-only?
3. Confirmation phrase: proposal `YES I KNOW WHAT I AM DOING` — final wording?
4. pgvector on the shared platform postgres — approve extension install (reverses earlier
   "no pgvector" stance)?
5. Should `runner`/`model` optionally be minted into the MCP JWT at token time (zero per-call
   args for static harnesses)?
