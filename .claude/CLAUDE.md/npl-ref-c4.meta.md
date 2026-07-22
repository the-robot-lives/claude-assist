# npl-ref-c4.meta.md — variant meta + loss ledger

## Variant
- **slug:** npl-ref-c4
- **derived from:** baseline
- **compactness level:** 4
- **style:** pure-npl (NPL reference-mode: rules inline; NPL scaffolds + repo reference fetched on demand)
- **language:** en (NPL-annotated)
- **size:** 6662 bytes / not-yet-measured tokens  (baseline: 11595 B, −4933 B / −42.5%)

## How it was made
The NPL-specific form of pointer-index (level 4, lossless-by-reference), but the definition source is the live, versioned NPL store rather than static docs. Immutable behavioral core (session-first, Trinity, terragrunt prereq) is wrapped in an `⌜🔒⌝` secure-prompt frame and kept inline; standing rules (frugal, Loom, worktrees, conventions) inline; all repo *reference* (overview, dirs, build/deploy, provisioning, secrets) moved behind `docs/` pointers; and the NPL notation + reasoning scaffolds are named for on-demand `NPLLoad` fetch instead of inlined. Uses NPL syntax markers throughout (🎯 attention, backtick highlight, `{…}` placeholders). Prose typos fixed; `protocol/` → `protocols/` with the four governance docs listed. Trinity clause present inline, verbatim.

## Alterations to raise eval scores
- none yet

## NPL detection + externalized elements
- **NPL detected:** yes — `mcp__tobor-root__NPLSpec` reachable; element names verified against it 2026-07-16 (NOT guessed).
- **Syntax elements referenced (inline markers, defs fetchable):** `syntax#highlight` (backtick), `syntax#attention` (🎯), `syntax#placeholder` (`{…}`), `special-sections#secure-prompt` (the `⌜🔒⌝` frame) — **all resolve in NPLSpec.**
- **Reasoning scaffolds externalized for the Trinity phases (fetch-on-need):**
  - `pumps#intent-declaration@1` → assumption grid (Orientation) — resolves (`<npl-intent>`, has the assumption table)
  - `pumps#plan-of-action@1` → mermaid intent (Orientation) — resolves (`<npl-poa>`, mermaid decision diagram)
  - `pumps#mind-reader@1` → minds-eye (Orientation) — resolves (`<npl-mindread>`, theory-of-mind)
  - `pumps#critical-analysis@1` → Friction (WEDGE/SHADOW/CRITIC) — resolves (`<npl-critique>`, strengths/weaknesses/verdict)
  - `pumps#reflection@1` → meta-review (Response) — resolves (`<npl-ref>`, assessment/improvements/validation)
- **Tier notation:** file's own DSL shorthand `NPLLoad <section>[#component]@<tier>` (`@0` defs default, `@1`/`@2` add worked examples) — a depth knob, not a resolution risk; all *names* resolve.

## Loss ledger
> Level 4 = lossless-by-reference, dual-backed. NPL scaffolds → `NPLLoad …` (verified via NPLSpec); repo reference → `docs/…` (verified `test -e`). Nothing dropped.

| what | why (method / level / vs intent) | recoverable-where |
|------|----------------------------------|-------------------|
| *(protected)* Trinity clause + session-first `⌜🔒⌝` core + terragrunt port-forward prereq | behavioral core — kept inline | kept inline, verbatim |
| *(protected)* all `dc`/`secret-bucket`/`terragrunt`/`export` command syntax cited | verbatim | kept inline, verbatim |
| NPL notation definitions (highlight/attention/placeholder/secure-prompt) | level 4 — fetch-on-need, not inlined | `NPLLoad syntax#…`, `special-sections#secure-prompt` (verified via NPLSpec) |
| Trinity-phase reasoning scaffolds | level 4 — fetch-on-need per phase | `NPLLoad pumps#{intent-declaration,plan-of-action,mind-reader,critical-analysis,reflection}@1` (verified via NPLSpec) |
| Repo overview / key dirs | level 4 — reference, moved | `docs/PROJ-ARCH.summary.md`, `docs/PROJ-LAYOUT.md`, `docs/layout/*.md` (verified) |
| Build & deploy / provisioning | level 4 — reference, moved | `docs/arch/deployment.md`, `docs/arch/provisioning.md`, `docs/layout/{utilities,terraform}.md` (verified) |
| Secrets cheatsheet | level 4 — reference, moved | `docs/secret-management.md` (verified) |

Coreference / omission flags: none. **Deep-load caveat:** an eval that never branches into a `NPLLoad`-gated path scores a lighter prompt than ships — the dataset's `deep-path-reference` case must exercise at least one fetch (NPL scaffold or doc) or this variant is scored optimistically.

## Eval  (dataset: CLAUDE.md.prompt, run not yet run)
| case id | criterion outcomes | pass? |
|---------|--------------------|-------|
| deep-path-reference | not yet run — must exercise an NPLLoad/doc fetch branch | — |

- **Aggregate:** not yet run — dataset: CLAUDE.md.prompt
- **required_pass:** not yet run
- **token_cost:** not yet measured (fetch cost only when depth is required)
- **reject_if hits:** not yet run

## Adhoc evals
- none

## Notes
Why it exists: demonstrates NPL-as-compression — reference by live versioned definition rather than static copy, the NPL analog of pointer-index. Prefer it where the NPL runtime (`NPLLoad`/`NPLSpec`) is reliably reachable and NPL elements recur. Weakness: doubly dependent — a broken `NPLLoad` element OR a moved `docs/` target silently downgrades it lossless→lossy, so promotion must re-verify BOTH the NPLSpec names and the doc targets. Evals must force the deep-load branches or they measure a prompt that silently under-performs.
