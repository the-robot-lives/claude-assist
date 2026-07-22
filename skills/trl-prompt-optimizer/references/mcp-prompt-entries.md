# MCP Prompt Entries

The served form of prompt lifecycle management: an MCP-hosted prompt store where each record carries its versions, eval rules, and dataset, and a `Prompt.Get` tool returns the right version for a caller/intent/budget — optionally as a multi-arm bandit that learns which version performs best.

> **STATUS: SPEC.** The tobor MCP currently exposes only Organization / Project / Session CRUD (and NPL discovery). Prompt tool families are **not live yet**. This document is the implementation spec for the elixir-mcp prompt store; the target implementation is `libs/elixir-mcp`. Until it ships, **file mode is the working fallback** — everything here maps onto the on-disk convention in [file-mode-convention.md](file-mode-convention.md), so a file-mode corpus can be lifted into the store later without rework.

---

## Why a store, not "just a prompt"

A bare prompt string throws away everything that makes optimization repeatable: what it's for, how to score it, which alternatives exist, and which one to serve to whom. A store record keeps all of it in one place and lets a caller *ask for behavior* ("I need the technical-writer prompt tuned for non-technical getting-started guides, under 800 tokens") rather than hard-coding a specific string.

---

## Record schema

```yaml
# a single prompt-store record
name: technical-writer                     # stable identifier
description: "Doc-writing prompt for developer-facing guides."

key_requirements:                          # what must work + why + focus
  - "Produces getting-started guides for NEW, non-technical users."
  - "Never assumes prior CLI familiarity."
  - "Output is skimmable: headings, short steps, one command per line."

eval_rules: >                              # the rubric, shared across versions
  Grade on: task fit (guide is genuinely beginner-oriented), completeness
  (covers install → first success), and token cost. Weighted; pass 0.8.

eval_dataset:                              # inline now; future codefre.sh links
  - id: first-run
    input: "Write the getting-started section for a CLI a non-dev will install."
    expect: "Prereqs, copy-paste install, a first command with expected output, a next step."
  # dataset_links: ["codefresh://project/<p>/datasets/tw-getting-started"]  # FUTURE

versions:                                  # multiple manners/styles/languages
  - slug: prose-en-c1
    style: plain
    language: en
    compactness: 1
    body: "You are a technical writer for absolute beginners. ..."
    eval_scores: { task_fit: 9.1, completeness: 8.8, token_cost: 640, aggregate: 0.86 }
    notes: "Baseline-tight prose. Best task_fit; largest of the compact set."
  - slug: yaml-meta-c3
    style: yaml-meta
    language: en
    compactness: 3
    body: "role: technical-writer\naudience: non-technical-beginner\n..."
    eval_scores: { task_fit: 8.7, completeness: 8.5, token_cost: 410, aggregate: 0.84 }
    notes: "Declarative; 36% fewer tokens than prose-en-c1; slight completeness dip."
  - slug: pointer-index-c4
    style: pointer-index
    language: en
    compactness: 4
    body: "role: technical-writer. Style rules: see style-guide#beginner. ..."
    eval_scores: { task_fit: 8.6, completeness: 8.9, token_cost: 300, aggregate: 0.85 }
    notes: "Style rules externalized to the style guide; costs one fetch."

defaults:
  version: prose-en-c1                      # store-level default
  overrides:                                # resolved by hierarchy (see below)
    project: { "<project-id>": yaml-meta-c3 }
    session: {}                             # filled at runtime
    agent:   { "codex-fast": yaml-meta-c3 } # a terse-favoring caller
```

Field mapping to file mode: `versions[].slug/style/language/compactness/body` ↔ `.{name}.md/{slug}.md`; `versions[].eval_scores/notes` + loss ledger ↔ `{slug}.meta.md`; `key_requirements/eval_rules/eval_dataset/defaults` ↔ the `.prompt` spec. The `pin` in file mode is the `defaults.version` here.

---

## The `Prompt.Get` contract

A special get-prompt call. It does not just fetch a string by name — it selects the best-fit version for the request.

### Inputs

| Input | Required | Meaning |
|-------|----------|---------|
| `name` | yes | Which prompt record. |
| `session` | yes | The calling work session (scopes overrides + bandit stats). |
| `caller` | yes | Who will *use* the prompt — an agent id or user. Drives agent-level defaults and per-caller bandit stats. |
| `intent` | yes | A statement of purpose ("getting-started guide for non-technical users"). Used for question-aware fit and bandit context. |
| `compactness` | no | Target level 0–5. |
| `token_budget` | no | Hard ceiling; wins over `compactness` on conflict. |
| `style` | no | Preferred methodology. |

`compactness` / `token_budget` / `style` filter the candidate versions; `intent` + `caller` + `session` rank the survivors.

### Behavior

Two modes:

**1. Default-serve (deterministic).** Resolve the default version through the hierarchy, filter by any requested axes, and return it. If a requested `compactness`/`token_budget` can't be met by any version, return the closest-fitting one **with a disclosed tradeoff**: which level it actually is and (from that version's loss ledger) what that costs. This is the safe default and the only mode available before behavior tracking is wired.

**2. Active-eval / multi-arm bandit.** When the record is in active-eval mode, `Prompt.Get` treats the versions as bandit arms:
- **Selection** picks among versions whose eval stats look closest-fit to the request (intent + caller + session + axes), balancing *exploit* (serve the current best) against *explore* (occasionally serve an under-sampled version to learn).
- **Tracking:** the output/behavior produced in response to the served prompt is recorded against that version — completion signals, downstream eval scores, task success — so the arm's stats update.
- Over time the store learns which version wins for which (intent, caller) profile, and default-serve for that profile converges on it.
- Bandit statistics basics (explore/exploit policy, how much data before a serve is trustworthy) live in [eval-and-scoring.md](eval-and-scoring.md).

In both modes, a requested `compactness`/`token_budget` is honored with a **known-lossy tradeoff disclosure** — the caller is told the level served and what was sacrificed to hit it, never given a smaller prompt silently.

### Output

```yaml
version: pointer-index-c4          # which arm was served
body: "..."                        # the prompt text
served_compactness: 4              # actual level (may differ from requested)
tradeoff: >                        # disclosure when request couldn't be met exactly
  Requested budget 250 tokens; closest version is 300 (level 4). Below this,
  only lossy level-5 exists, which drops the style-guide detail (see ledger).
mode: bandit | default             # how it was selected
arm_stats: { serves: 42, aggregate: 0.85, ci: [0.81, 0.89] }  # bandit mode only
```

---

## Defaults hierarchy

When more than one default applies, resolve **most specific wins**:

```
agent  >  session  >  project  >  store default
```

- **agent** — a specific caller's preference (e.g. a terse-favoring fast model always gets the compact version).
- **session** — a preference set for the current work session (e.g. "this session is token-constrained; prefer level 4").
- **project** — a project-wide default (e.g. this project standardizes on YAML meta-prompts).
- **store default** — `defaults.version`, the fallback when nothing more specific matches.

A request's explicit `compactness`/`style`/`token_budget` filters *within* whatever the hierarchy resolves — the hierarchy picks the starting default; the request narrows the candidate set. In file mode this hierarchy collapses to the single `pin` (agent/session/project context isn't available on disk), which is why the store is the richer target.

---

## Migration from file mode to the store

Because the schemas are aligned, lifting a file-mode corpus into the store is mechanical:
1. `.prompt` spec → record header (`name`, `description`, `key_requirements`, `eval_rules`, `eval_dataset`).
2. Each `.{name}.md/{slug}.md` + `.meta.md` → a `versions[]` entry (`body` + `eval_scores` + `notes`).
3. `pin` → `defaults.version`; add `overrides` as agent/session/project defaults become known.
4. Turn on active-eval to start collecting bandit stats; before enough data accrues, the store serves the default deterministically.

Build the store on file mode first: it's the fallback that ships today and the seed corpus the store ingests.
