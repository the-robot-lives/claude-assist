# Dynamic Prompt Tailoring

Skill-level application of the prompt variant-group convention: every instructional markdown file in a skill becomes a tailorable prompt (spec + variants dir + live symlink), and checked-in **use-case overlays** re-pin those symlinks per usage profile without touching the skill's defaults.

The **per-file** convention (spec format, variants dir, meta sidecars, symlink/pin selection) is owned by **trl-prompt-optimizer** — see `skills/trl-prompt-optimizer/references/file-mode-convention.md`. This document covers what trl-skill-engineer adds: applying that convention across a whole skill at scaffold time, the `.USE-CASE/` overlay system, and the use-case-aware enable/disable flow.

> For generating and scoring the variants themselves (compression methods, style transforms, eval corpora), hand off to **trl-prompt-optimizer**.
> For the underlying media-tool payload schema, see `skills/shared/asset-prompt-payload-schema.md` (v0.4).

---

## Activation

Tailored scaffolding is **off by default**. Enable it either way:

| Signal | Form | Effect |
|--------|------|--------|
| Environment variable | `DYNAMIC_SKILLSET_TAILOR=enabled` | All scaffolds this session generate variant groups |
| In-conversation flag | user states `DYNAMIC_SKILLSET_TAILOR=enabled` (or asks for "tailorable" / "variant-group" scaffolding) | Same, scoped to the request |

When active, scaffold generation produces the tailored layout below **and** seeds the eval material (`.prompt` specs with `eval.rules` + `eval.dataset` stubs) alongside it. When inactive, generate the plain layout from [scaffold-specification.md](scaffold-specification.md) unchanged.

---

## What Participates

| File class | Becomes a variant group? | Notes |
|------------|--------------------------|-------|
| `SKILL.md` | Yes | The highest-value tailoring target |
| `INTRODUCTION.md` | Yes | I/O contract prose is compressible |
| `references/**/*.md` | Yes | Instruction + knowledge-base prompts |
| `kb/**/*.md` | Yes | Same |
| `assets/**` | No | Fillable templates are data, not prompts |
| `scripts/**` | No | Not prompts |
| `*.media.prompt`, `*.md.prompt` | No | Already specs; a skill may legitimately contain regular media-tool prompts — they pass through untouched |
| `.{name}.md/` variant dirs, `.USE-CASE/` | No | Machinery, never nested |

Rule of thumb: if the file is loaded into an agent's context as instructions or knowledge, it participates; if it is filled in, executed, or rendered, it does not.

---

## Tailored Scaffold Layout

For each participating file `{FILE}.md`, the scaffold generates the three parts of file mode, seeded at baseline:

```bash
mkdir .{FILE}.md
# write the authored content as the permanent level-0 variant
mv {FILE}.md .{FILE}.md/baseline.md
# write the spec (template: trl-prompt-optimizer/assets/prompt-spec-template.md.prompt)
$EDITOR {FILE}.md.prompt
# live file becomes the selection symlink
ln -s .{FILE}.md/baseline.md {FILE}.md
```

A freshly tailored skill therefore looks like:

```
skills/{skill-name}/
├── SKILL.md                 -> .SKILL.md/baseline.md
├── SKILL.md.prompt          # spec: key_requirements, eval rules + dataset, axes, pin
├── .SKILL.md/
│   ├── baseline.md          # authored content, retained forever (level 0)
│   └── baseline.meta.md
├── INTRODUCTION.md          -> .INTRODUCTION.md/baseline.md
├── INTRODUCTION.md.prompt
├── .INTRODUCTION.md/…
├── references/
│   ├── agent-playbook.claude-code.md        -> .agent-playbook.claude-code.md/baseline.md
│   ├── agent-playbook.claude-code.md.prompt
│   └── .agent-playbook.claude-code.md/…
├── assets/…                 # untouched
├── scripts/
└── .USE-CASE/               # empty until a use case is declared (see below)
```

Naming notes, aligned with file-mode-convention.md (these override looser phrasings elsewhere):

- The seed variant slug is **`baseline`** — it is both the original and the initial default. "Default" is not a variant name; it is whatever the live symlink points at (best-eval auto-selection, or the spec's `pin`).
- Variant meta sidecars are **`{slug}.meta.md`** (how it was compressed, why, alterations to raise eval scores, eval scores from the spec's dataset plus any adhoc evals, loss ledger).
- Variant slugs encode axes (`pointer-index-c4`, `ultra-compact-zh-c5`) and MAY carry an in-place iteration suffix: `{slug}.v{major.minor}.md` (e.g. `npl-mandarin-farsi-mix.v2.4.md`). Overrides reference the exact filename stem.

As trl-prompt-optimizer generates additional variants, they accumulate in the variants dirs; promoting one is a single symlink repoint. Nothing in this layout requires the optimizer to have run — a baseline-only tailored skill behaves byte-identically to a plain one.

---

## Use-Case Overlays (`.USE-CASE/`)

A **use case** is a named usage profile for the skill ("onboarding non-technical users", "token-starved fast-model sessions", "zh-language deployments"). Each gets a sparse override declaration plus a fully materialized symlink tree that can be mounted *instead of* the skill root. Overlays are **checked in**.

```
.USE-CASE/
├── {slug}.meta.yaml         # hand-authored: intent, rubric emphasis, sparse overrides
└── {slug}/
    ├── meta.lock            # machine-written at each refresh (YAML content, no extension)
    └── overlay/             # mirrors the skill tree — symlinks only
        ├── SKILL.md         -> $SKILL_ROOT/.SKILL.md/npl-mandarin-farsi-mix.v2.4.md   (overridden)
        ├── INTRODUCTION.md  -> $SKILL_ROOT/INTRODUCTION.md                            (not overridden)
        ├── references/
        │   └── agent-playbook.claude-code.md -> $SKILL_ROOT/references/agent-playbook.claude-code.md
        └── assets/          -> symlinks to root originals
```

### `{slug}.meta.yaml` — the declaration

```yaml
# .USE-CASE/zh-compact.meta.yaml
use_case: zh-compact
description: "Chinese-language deployments on token-constrained fast models."
intent: >
  Skill consumed by zh-locale agents; instruction fidelity matters more than
  KB completeness; hard context budget.
rubric_emphasis:              # which eval axes matter most when matching/judging variants
  - instruction_compliance
  - token_cost
axes: { compactness: 4, style: null, language: zh }   # defaults for new-variant requests

overrides:                    # SPARSE — only files that deviate from root default
  SKILL.md: npl-mandarin-farsi-mix.v2.4
  references/agent-playbook.claude-code.md: yaml-meta-c3

auto_overrides: {}            # written by refresh step 3; review then promote into overrides
```

### Overlay symlink semantics

| Entry | Symlink target | Why |
|-------|---------------|-----|
| Overridden prompt file | `$SKILL_ROOT/.{FILE}.md/{variant}.md` — direct to the variant | The override must survive root default changes |
| Non-overridden prompt file | `$SKILL_ROOT/{FILE}.md` — the root symlink itself | Double indirection: root promotions flow through automatically |
| Non-participating file (assets, `*.media.prompt`, scripts) | `$SKILL_ROOT/<path>` | Pass-through |
| `*.md.prompt` specs, `.{FILE}.md/` dirs, `.USE-CASE/` | **not mirrored** | The overlay is a consumption view, not a workshop |

### `meta.lock` — the drift ledger

Written by every refresh; never hand-edited. YAML content; the `.yaml` extension is deliberately dropped to mark it machine-owned.

```yaml
refreshed_at: 2026-07-16T10:40:00Z
skill_ref: <git sha or content hash of the skill root at refresh time>   # optional
defaults:                     # resolved root default for EVERY participating file at refresh
  SKILL.md: baseline
  INTRODUCTION.md: baseline
  references/agent-playbook.claude-code.md: pointer-index-c4
census:                       # full participating-file list (detects adds/removals)
  - SKILL.md
  - INTRODUCTION.md
  - references/agent-playbook.claude-code.md
```

---

## Build / Refresh Algorithm

Run when creating an overlay, after the optimizer lands new variants, or on use-case-aware enable.

1. **Mirror pass.** Rebuild `overlay/` as a pure symlink tree: every participating file → its root symlink; every non-participating file → the root original. (An `rsync`-style walk that plants links instead of copying; equivalently `cp -rs` filtered by the participation rules.)
2. **Drift check** *(refresh only)*. Diff the current resolved defaults and file census against `meta.lock`: collect **default-changed** files, **new** files, and **removed** files. A first build with no lock treats everything as new.
3. **Re-evaluate drifted entries.** For each changed/new file, judge whether the root default still satisfies this use case: score the available variants' recorded evals against `rubric_emphasis`. Where a different variant clearly wins, record it under `auto_overrides` in `{slug}.meta.yaml` (human reviews and promotes to `overrides`). Where no variant satisfies, flag for optimization (see enable flow below).
4. **Apply overrides.** For every entry in `overrides` + `auto_overrides`, repoint the overlay symlink directly at `$SKILL_ROOT/.{FILE}.md/{variant}.md`. Fail loudly on a dangling variant reference — never leave a broken live symlink.
5. **Write `meta.lock`.** New timestamp, full defaults snapshot, full census.

The ordering matters: overrides are applied **after** the mirror pass so a refresh can never silently lose an override, and the lock is written **last** so a failed refresh leaves the previous lock intact for retry.

---

## Use-Case-Aware Enable / Disable

> **STATUS: SPEC.** Extends the skill-manage crate embedded in `utilities/agent/llm-toolkit/`
> (Rust; today `enable`/`disable` plant plain symlinks from provider install roots into source
> trees). Until it ships, run the flow manually: build/refresh the overlay per the algorithm
> above, then `ln -s $SKILL_ROOT/.USE-CASE/{slug}/overlay ~/.claude/skills/{skill-name}`.

```
llm-toolkit skill enable skill <name> --use-case <slug>            # mount an existing overlay
llm-toolkit skill enable skill <name> --intent "<free text>" [--use-case <slug>] [--optimize]
llm-toolkit skill disable skill <name>                             # unchanged; removes managed symlink
```

Enable flow with `--intent`:

1. **Resolve.** `--use-case` given → load its meta; else derive a candidate slug from the intent text.
2. **Match.** For each participating file, score existing variants' eval meta against the rubric points most relevant to the stated intent (the `rubric_emphasis` axes, or intent-derived weights). A variant is a **satisfactory near-match** when it meets the spec's `pass_threshold` on those weighted axes.
3. **Compose.** Satisfactory matches → build/refresh the overlay with those selections (named overlay if `--use-case` given, else ephemeral under the session scratchpad) and mount it as the install-root symlink.
4. **Optimize (opt-in).** Files with **no** satisfactory near-match: only if `--optimize` (or the user asks), hand off to **trl-prompt-optimizer** to synthesize a new variant at the use case's `axes`, score it against the spec's dataset, write its `{slug}.meta.md`, then add the override. Without `--optimize`, mount the root default for those files and report the gap.
5. **Report.** Always disclose per-file: served variant, its relevant eval scores, and any known-lossy tradeoff — never silently serve a lossier variant.

Disable is untouched: removing the install-root symlink unmounts the overlay; the checked-in `.USE-CASE/` data persists.

---

## Quality Gates

Add to the standard [quality-checklist.md](quality-checklist.md) pass when a skill is tailored:

- [ ] Every participating file is a symlink resolving inside its own `.{FILE}.md/` dir; no dangling links anywhere in the skill or its overlays
- [ ] Every variants dir retains `baseline.md` + `baseline.meta.md`
- [ ] Every `.prompt` spec has `key_requirements` and ≥3 `eval.dataset` entries
- [ ] The live symlink target has eval scores in its meta (or is the pinned baseline)
- [ ] Each `.USE-CASE/{slug}/meta.lock` is newer than the last change to any root default it snapshots (stale lock ⇒ run refresh)
- [ ] `overrides` reference variant files that exist; `auto_overrides` is empty at ship time (reviewed and promoted or dropped)

> For npl-mcp fetch-stub bodies as an alternative to local variant bodies, see [npl-mcp-prompt-stubs.md](npl-mcp-prompt-stubs.md) — a stub can itself be a variant, so an overlay can choose per use case between a local body and an MCP-served prompt.
