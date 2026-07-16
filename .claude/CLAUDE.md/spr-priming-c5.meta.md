# spr-priming-c5.meta.md — variant meta + loss ledger

## Variant
- **slug:** spr-priming-c5
- **derived from:** baseline
- **compactness level:** 5
- **style:** telegraphic-symbolic (SPR — Sparse Priming Representations: minimal associative cue lists)
- **language:** en
- **size:** 5063 bytes / not-yet-measured tokens  (baseline: 11595 B, −6532 B / −56.3%)

## How it was made
Baseline recast as Sparse Priming Representations (Shapiro-style): short, declarative, standalone assertions grouped under minimal headers (SESSION, IDENTITY, REPO, DEPLOY, SECRETS, TERRAFORM, CONVENTIONS, ACCORDS), each cue engineered to *prime* latent model knowledge rather than spell every detail out. Protected spans are kept as verbatim full-fidelity islands inside the cue stream: the `Session.Create` ToolCall block, the `echo $NPL_*` block, the terragrunt command block + MinIO port-forward warning, and the Trinity two-line clause (placed at the very top). Prose typos fixed; `protocols/` listed with governance docs. Trinity clause ADDED, verbatim.

## Alterations to raise eval scores
- none yet

## Loss ledger
> Level 5 = lossy. A cue that a competent model reliably re-expands counts as retained; where re-expansion is uncertain, the fact is ledgered dropped. Protected islands stay verbatim.

| what | why (method / level / vs intent) | recoverable-where |
|------|----------------------------------|-------------------|
| *(protected)* Trinity clause (2-line block) | ADDED at top, verbatim | kept inline, verbatim |
| *(protected)* session-first flow + `Session.Create` + `echo $NPL_*` + env-var non-expansion | full-fidelity island | kept inline, verbatim |
| *(protected)* terragrunt block + MinIO port-forward prereq + KUBE_*/AWS_* exports | full-fidelity island | kept inline, verbatim |
| Full `dc`/`secret-bucket` secrets cheatsheet | level 5 — DROPPED, replaced by pointer | `docs/secret-management.md` (verified) |
| Per-command flag catalogs (`docker-build`/`docker-push`/`helm-upgrade` full option lists) | level 5 — cue-ified to command names + purpose; exact flags dropped | **DROPPED — baseline only** |
| Directory-purpose detail, architecture prose (secrets-flow steps, tier purposes) | level 5 — compressed to single-line cues; nuance dropped | **DROPPED — baseline only** |
| Platform module enumeration exactness / project-structure detail | level 5 — cue-summarized | **DROPPED — baseline only** (cue primes the gist) |

Coreference / omission flags: none — SPR cues are standalone assertions by construction. Borderline: the technique BETS that priming cues activate the right latent knowledge; where a model lacks that latent knowledge, a cue under-specifies vs baseline — that is the declared level-5 risk.

## Eval  (dataset: CLAUDE.md.prompt, run not yet run)
| case id | criterion outcomes | pass? |
|---------|--------------------|-------|
| — | not yet run | — |

- **Aggregate:** not yet run — dataset: CLAUDE.md.prompt
- **required_pass:** not yet run
- **token_cost:** not yet measured
- **reject_if hits:** not yet run

## Adhoc evals
- none

## Notes
Why it exists: SPR (Sparse Priming Representations) is a community-practice compression technique — it appears in the skill's research notes (`references/research/nerority-review-2026-07-16.md`) as a catalog *candidate* but is NOT yet in the operative `style-transforms.md` catalog. This variant is its first corpus data point: does associative priming preserve instruction compliance at level 5, or does the bet on latent knowledge cost fact recall the eval will catch? Prefer it only for models known to hold the primed background. Weakness: the whole method is a wager on latent knowledge; unlike pointer-index the dropped detail has no in-prompt pointer for most cues (only the secrets cheatsheet does).
