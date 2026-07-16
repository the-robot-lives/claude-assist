# NPL Compression Integration

Noizu Prompt Lingua (NPL) is a compression method in its own right: instead of inlining the full definition of a prompt element, emit a prompt that **fetches the definition on demand** via the `NPLLoad` MCP tool, at the necessary complexity tier. The shipped prompt carries a reference and a load instruction, not the body — compactness level 4 (lossless-by-reference), backed by a live definition source rather than a static doc pointer.

> This is the NPL-specific form of the pointer-index transform in [style-transforms.md](style-transforms.md). Use it only when NPL is actually available (see detection below); otherwise the load instruction is dead weight and you should use a plain doc pointer instead.

---

## Detection — is NPL available here?

Apply these rules in order. **Positive signals:**

1. **MCP tools present** — the `NPLLoad` and `NPLSpec` tools are reachable (e.g. `mcp__tobor-root__NPLLoad`, `mcp__tobor-root__NPLSpec`). This is the strongest signal: it means definitions can be fetched at runtime.
2. **NPL project present** — `projects/NoizuPromptLingo/` exists in the repo, or the project exposes NPL loaders/specs (`NPLLoad`/`NPLSpec` surfaces) in its tooling.

**Never treat these as signals:**

- **`$NPL_PROJECT` / `$NPL_ORG` are NOT install signals.** They are tobor *session slugs* — the organization/project a work session is registered under. A repo can have them set and have no NPL runtime at all. Detecting NPL from them is a known trap; do not do it.

**If NPL is not detected:** fall back to the plain pointer-index transform (doc pointers instead of `NPLLoad` fetches). Say so in the variant meta: "NPL not detected; used static doc pointers for reference-mode."

---

## The on-demand `NPLLoad` fetch pattern

The point of NPL compression is that a prompt does not need to *contain* an element's full definition to *use* it — it needs to name the element and instruct the reader (the model, at runtime) to load the definition when the task actually requires that depth.

**Inlined (heavy).** The prompt carries the entire definition of every element it might use, every turn:

```
[full multi-paragraph definition of element A]
[full multi-paragraph definition of element B]
[full multi-paragraph definition of element C]
...then the actual task...
```

**Reference-mode (light).** The prompt names the elements and instructs an on-demand load at the tier the task needs:

```
Load element definitions on demand as needed for this task:
- for A: NPLLoad A@tier-2
- for B: NPLLoad B@tier-1   (only the summary tier is needed here)
- C is not needed unless the task branches into <case>; load C@tier-3 then.
...then the actual task...
```

The exact element names and load syntax come from `NPLSpec` in the target environment — query it rather than guessing names. The *pattern* is constant: **name + tier + a load instruction, conditioned on need.**

Why this is lossless-by-reference, not lossy: the definition still exists and is retrievable; it just isn't paid for on every turn. The cost is a fetch when (and only when) the depth is required — the same tradeoff as the pointer-index doc read, but the source is authoritative and versioned.

---

## Complexity-tier selection

NPL element definitions can be loaded at varying depth. Loading the deepest tier of everything defeats the purpose. Select the *minimum* tier the task actually needs:

| Tier intent | Load when | Typical content |
|-------------|-----------|-----------------|
| Summary / lightest | The prompt only needs to *reference* the element or route on it | Name, one-line purpose, invocation form |
| Standard | The model must *apply* the element in a routine way | Purpose + core rules + common usage |
| Deep / full | The task hinges on edge cases, formal syntax, or exhaustive rules | Full definition, edge cases, formal grammar |

Selection heuristic:
- Start at the lightest tier that could plausibly work.
- Escalate a tier only for elements the *declared intent* leans on heavily (question-aware, per [compression-methods.md](compression-methods.md) method 5).
- Gate deep tiers behind conditions ("load the full grammar only if the input fails to parse") so the cost is paid on the branch that needs it, not up front.

This mirrors the budget controller: spend depth where the intent needs it, keep everything else at summary.

---

## Worked micro-examples

### Micro-example 1 — a routing prompt

**Before (inlined, ~heavy).** A prompt that classifies an incoming request into one of five agent roles, inlining a paragraph defining each role.

**After (reference-mode).**
```
Classify the request into one role. Load each role's definition only if the
request is a plausible match; otherwise route on the one-line summaries:
  research → NPLLoad role.research@summary
  code     → NPLLoad role.code@summary
  data     → NPLLoad role.data@standard   (needs its rules to disambiguate)
  ux       → NPLLoad role.ux@summary
  ops      → NPLLoad role.ops@summary
Emit {role, confidence}.
```
Most turns touch only summary tiers; `role.data` escalates to standard because the intent (disambiguation) leans on it. The five full role paragraphs never ship.

### Micro-example 2 — a formatting element used rarely

**Before.** A prompt inlines the full definition of a strict output-format element that only applies when the user asks for a formal export.

**After (conditional deep load).**
```
Normal replies: prose.
If the user requests a formal export, load the format spec then comply:
  NPLLoad format.formal-export@deep
```
The deep definition is fetched on the rare export branch only — level-4 by reference, gated by condition. Ledger entry: *what* = full formal-export grammar; *why* = level 4, reference-mode, needed only on export branch; *recoverable-where* = `NPLLoad format.formal-export@deep` (verified: element present in NPLSpec).

### Micro-example 3 — falling back when NPL is absent

Detection finds no `NPLLoad`/`NPLSpec` and no `projects/NoizuPromptLingo/`. Do **not** emit `NPLLoad` instructions (they would be inert). Instead use a static pointer: "See `docs/roles.md` for full role definitions." Note in the meta that NPL was not detected.

---

## Interaction with the rest of the skill

- **File mode.** An NPL reference-mode variant is just a variant at compactness level 4; store it in `.{name}.md/` with a meta recording which elements were externalized and at what tier ([file-mode-convention.md](file-mode-convention.md)).
- **Eval.** Reference-mode changes *when* information loads, not *whether* it exists — so evals must exercise the branches that trigger deep loads, or they will score a light prompt that silently under-performs on the deep path. Put a deep-path case in the dataset ([eval-and-scoring.md](eval-and-scoring.md)).
- **Verification.** Before shipping a `NPLLoad X@tier` instruction, confirm element `X` exists at that tier via `NPLSpec`. An unresolvable load is the NPL equivalent of a broken doc pointer — a silent omission.
