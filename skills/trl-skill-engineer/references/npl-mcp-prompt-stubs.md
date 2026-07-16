# NPL-MCP Prompt Stubs

Scaffold mode in which a skill's instructional files are not full prompt bodies but **fetch stubs** — short directives that tell the consuming agent to pull the actual prompt from the npl-mcp prompt store at load time, optionally pinned to a variant and version. This trades a tool round-trip for centralized versioning, per-caller defaults, and bandit-driven selection.

> **STATUS: SPEC-DEPENDENT.** Stubs target the MCP prompt store specified in `skills/trl-prompt-optimizer/references/mcp-prompt-entries.md`, which is itself **not live yet** (target implementation: `libs/elixir-mcp`). Generate stubs only when the user opts in AND understands the store dependency; every stub must carry a working local fallback.

---

## Activation

| Signal | Form |
|--------|------|
| Environment variable | `NPL_MCP_ENABLED_SKILLS=true` |
| In-conversation flag | user states `@NPL_MCP_ENABLED_SKILLS=true` or asks for "MCP-served" / "fetch-stub" skill files |

When active, scaffold generation emits stub bodies (below) for participating files — the same participation rules as [dynamic-prompt-tailoring.md](dynamic-prompt-tailoring.md) — instead of, or alongside, local variant groups.

---

## Stub File Format

A stub is a complete, self-describing markdown file — small enough to be negligible in context, informative enough to work when the fetch cannot happen.

```markdown
<!-- npl-mcp prompt stub · v1 -->
# {Human Title}

> **Load via npl-mcp.** This file is a stub; the operative prompt is served by the
> npl-mcp prompt store.

- **Prompt:** `{prompt-name}`            <!-- e.g. skill-engineer/agent-playbook -->
- **Pin:** `{prompt-name}@{variant}@{version}`   <!-- omit for default variant, active version -->
- **Fetch:** call `Prompt.Get` with `name`, current `session`, `caller`, and an
  `intent` statement of the task at hand; pass `compactness` / `token_budget` /
  `style` only when the session or use case sets them.
- **Fallback:** if the prompt tool family is unavailable, read
  `{relative path to local baseline, e.g. .agent-playbook.claude-code.md/baseline.md}`.

{One-paragraph summary of what the fetched prompt covers, so a reader who cannot
fetch still knows what this file is for.}
```

Rules:

- **Name, description, fetch, fallback are all mandatory.** A stub without a resolvable fallback is a broken skill file.
- The `intent` passed to `Prompt.Get` comes from the live task, not the stub — the stub only says *that* intent must be passed.
- Stubs never embed the prompt body. If a body must ship locally, that's a variant group, not a stub.

## Addressing Grammar

```
{prompt-name}                      → default variant, its active version
{prompt-name}@{variant}            → named variant, its active version
{prompt-name}@{variant}@{version}  → exact pin
```

Examples: `technical-writer`, `technical-writer@yaml-meta-c3`, `technical-writer@yaml-meta-c3@2.4`.

---

## Required Upstream Extensions

The current store record (mcp-prompt-entries.md) has a flat `versions[]` list where each slug is effectively a variant with a single body. Stub addressing needs variants to be **independently versioned**, additively:

```yaml
# record-schema delta (additive; flat versions[] readers unaffected)
variants:
  - slug: yaml-meta-c3
    style: yaml-meta
    language: en
    compactness: 3
    default_version: "2.4"          # NEW — the variant's active version
    versions:
      - version: "2.4"
        body: "…"
        eval_scores: { … }
        notes: "…"
      - version: "2.3"
        body: "…"
        eval_scores: { … }

defaults:
  variant: yaml-meta-c3             # NEW — per-record default variant
  # existing agent > session > project override hierarchy applies unchanged,
  # its values now naming variants (optionally variant@version)
```

Resolution: `name` → `defaults.variant` (through the agent > session > project hierarchy) → that variant's `default_version`, unless the request pins deeper. Bandit mode selects among variants' active versions.

**Media-tool side** (`utilities/agent/media-tool/`): the `type: prompt` chat-type registration is already specced in file-mode-convention.md's integration appendix; this mode additionally needs a **publish step** — pushing a generated variant (body + meta + eval scores) into the store as a new version of its variant, and bumping `default_version` only on explicit promotion.

**elixir-mcp side** (`libs/elixir-mcp`): prompt records/`Prompt.Get` per mcp-prompt-entries.md plus the variant/version dimensions above. (The existing `Noizu.MCP.RenderCtx` verbosity seam is adjacent machinery for *tool descriptions*, not this store — don't conflate them.)

---

## Composing with Variant Groups and Overlays

A stub can live **as a variant** inside a file's variants dir (slug suggestion: `mcp-stub`):

```
references/.agent-playbook.claude-code.md/
├── baseline.md            # full local body — also the stub's fallback target
├── baseline.meta.md
├── mcp-stub.md            # the fetch stub above
└── mcp-stub.meta.md       # eval note: scores == the store-served prompt's scores + fetch cost
```

This makes the local-vs-served decision just another selection: the root symlink or a `.USE-CASE/` overlay picks `mcp-stub` for connected environments and `baseline` (or a compact local variant) for offline/headless ones. Cron/headless caveat from the harness docs applies — interactively-authenticated MCP servers may be absent, so **never** ship a use-case overlay that selects `mcp-stub` for a headless profile.

## Quality Gates

- [ ] Every stub's fallback path resolves to an existing file
- [ ] Pinned addresses (`@variant@version`) exist in the store (or are marked pending with the fallback active)
- [ ] No stub selected by a headless/offline use-case overlay
- [ ] Stub summary paragraph present (a fetch-less reader can still orient)
