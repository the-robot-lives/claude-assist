# ultra-terse-lossy-c5.meta.md — variant meta + loss ledger

## Variant
- **slug:** ultra-terse-lossy-c5
- **derived from:** baseline (via ultra-terse-min-loss-c3)
- **compactness level:** 5
- **style:** shorthand (telegraphic one-block sections; secrets cheatsheet dropped → pointer)
- **language:** en
- **size:** 4280 bytes / not-yet-measured tokens  (baseline: 11595 B, −7315 B / −63.1%)

## How it was made
The telegraphic ultra-terse form taken past the lossless floor into declared loss: the full `dc`/Infisical/`secret-bucket` secrets cheatsheet is DROPPED and replaced by a pointer to `docs/secret-management.md` (+ the git history of `CLAUDE.md`), and command flag catalogs are collapsed to their common forms. Behavioral rules and protected items stay inline verbatim. Prose typos fixed; `protocol/` → `protocols/` with the four governance docs listed. Trinity clause ADDED with the verbatim two-line block. Self-labels the loss in its H1.

## Alterations to raise eval scores
- none yet

## Loss ledger
> Level 5 = lossy. Dropped facts are recoverable ONLY from baseline / the named pointer. Protected items remain inline verbatim.

| what | why (method / level / vs intent) | recoverable-where |
|------|----------------------------------|-------------------|
| *(protected)* Trinity clause (2-line block) | ADDED, verbatim — never dropped | kept inline, verbatim |
| *(protected)* session-first flow + `Session.Create` + env-var non-expansion + MinIO port-forward prereq | behavioral — kept inline | kept inline, verbatim |
| *(protected)* core `terragrunt`/`dc`/`secret-bucket` invocations named | verbatim | kept inline, verbatim |
| Full `dc`/Infisical/`secret-bucket` secrets cheatsheet (lookup/set/compare/agent-safe forms, examples) | level 5 — DROPPED, replaced by pointer | `docs/secret-management.md` (verified) + git history of `CLAUDE.md` |
| Per-command flag catalogs (`docker-build --pick/--native`, `helm-upgrade --list/--tier/--preview/…` full option lists) | level 5 — collapsed to common forms, detail dropped | **DROPPED — baseline only** |
| Some architecture prose detail (exact wording of secrets flow / tier purposes) | level 5 — compressed past nuance | **DROPPED — baseline only** |

Coreference / omission flags: none — telegraphic register is pronoun-free. Borderline: flag-catalog collapse assumes the reader can discover options via `--help`; the exact option set is baseline-only.

## Eval  (dataset: CLAUDE.md.prompt, run not yet run)
| case id | criterion outcomes | pass? |
|---------|--------------------|-------|
| secrets-discipline | not yet run — probes whether the dropped cheatsheet still yields agent-safe behavior via the pointer | — |

- **Aggregate:** not yet run — dataset: CLAUDE.md.prompt
- **required_pass:** not yet run
- **token_cost:** not yet measured
- **reject_if hits:** not yet run

## Notes
Why it exists: the deliberate lossy floor — the corpus lesson is that at ~4.3KB this DROPPED ~4KB of facts yet landed *larger* than pointer-index-c4 (4212 B), which moved the same material losslessly. It's kept as the cautionary data point: past the inline floor, prefer *moving* reference (level 4) over *deleting* it (level 5). Prefer this variant only when the `docs/` tree may be absent AND a hard size cap forbids the pointer-index rows. Weakness: dropped facts are unrecoverable in-prompt; agent-safe secrets behavior now depends on the model actually following the pointer.

## Adhoc evals
- none
