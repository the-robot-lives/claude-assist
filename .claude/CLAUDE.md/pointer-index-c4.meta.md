# pointer-index-c4.meta.md — variant meta + loss ledger

## Variant
- **slug:** pointer-index-c4
- **derived from:** baseline
- **compactness level:** 4
- **style:** pointer-index (behavioral rules inline; reference material denoted + verified `docs/` pointer)
- **language:** en
- **size:** 4212 bytes / not-yet-measured tokens  (baseline: 11595 B, −7383 B / −63.7%)

## How it was made
Baseline split by the level-4 discipline: behavioral rules that bind every turn (session-first, Trinity, frugality, Loom, worktrees, conventions, end-in-mind) kept **inline**; all reference material (repo overview, directory detail, build/deploy commands, provisioning, secrets cheatsheet) reduced to a one-line "thing → doc" denotation pointing into `docs/`. Detail is one verified doc-read away. Prose typos fixed; the stale `protocol/` reference corrected to `protocols/` (with governance docs) in the layout pointer row; a duplicate list number (two "5.") corrected to 5/6. Trinity clause ADDED (new requirement) as inline Rule 2 with the verbatim two-line block.

## Alterations to raise eval scores
- none yet

## Loss ledger
> Level 4 = lossless-by-reference. Reference material MOVED to verified `docs/` targets; rules kept inline. Every pointer target was `test -e`-verified present 2026-07-16.

| what | why (method / level / vs intent) | recoverable-where |
|------|----------------------------------|-------------------|
| *(protected)* Trinity clause (2-line block) | ADDED as inline Rule 2, never moved | kept inline, verbatim |
| *(protected)* session-first flow + `Session.Create` + env-var non-expansion + MinIO port-forward prereq | behavioral rules — kept inline | kept inline, verbatim |
| *(protected)* `terragrunt run --all` port-forward warning | kept inline in the provisioning pointer row | kept inline, verbatim |
| Repo overview / directory layout | level 4 — reference, moved | `docs/PROJ-ARCH.summary.md`, `docs/PROJ-LAYOUT.summary.md` / `docs/PROJ-LAYOUT.md` / `docs/layout/*.md` (verified) |
| Build & deploy command catalog (`docker-*`, `helm-upgrade`, `deploy-service`, tiers) | level 4 — reference, moved | `docs/arch/deployment.md` (verified) |
| Provisioning / Terragrunt-OpenTofu stack ordering | level 4 — reference, moved | `docs/arch/provisioning.md`, `docs/layout/terraform.md` (verified) |
| Full `dc`/Infisical/secret-bucket secrets cheatsheet | level 4 — reference material, moved (not a per-turn rule) | `docs/secret-management.md` (verified) |
| Utilities incl. `liquibase-shell` | level 4 — reference, moved | `docs/layout/utilities.md` (verified) |
| Architecture rationale, network topology | level 4 — reference, moved | `docs/arch/decisions.md`, `docs/infrastructure-topology.md` (verified) |

Coreference / omission flags: none — each pointer row names its subject explicitly. Risk noted: a level-4 variant silently degrades to lossy if any target moves; all targets verified at authoring time and must be re-verified before promotion.

## Eval  (dataset: CLAUDE.md.prompt, run not yet run)
| case id | criterion outcomes | pass? |
|---------|--------------------|-------|
| deep-path-reference | not yet run — this variant is the primary deep-path case (must follow pointer, not guess) | — |

- **Aggregate:** not yet run — dataset: CLAUDE.md.prompt
- **required_pass:** not yet run
- **token_cost:** not yet measured (smallest lossless option — reference cost is a doc read per area)
- **reject_if hits:** not yet run

## Adhoc evals
- none

## Notes
Why it exists: the corpus's headline result — biggest single win (−63.7%) by *moving* reference rather than deleting facts, staying lossless. Prefer it when the model reliably follows pointers and the `docs/` tree is present and current. Weakness: every referenced area costs a doc read, and a dangling pointer turns lossless→silently-lossy — promotion MUST re-verify all targets. The eval dataset's `deep-path-reference` case exists to catch a model that guesses from the one-liner instead of reading the target.
