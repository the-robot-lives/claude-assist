# ultra-terse-min-loss-c3.meta.md — variant meta + loss ledger

## Variant
- **slug:** ultra-terse-min-loss-c3
- **derived from:** baseline
- **compactness level:** 3
- **style:** shorthand (telegraphic bold-header sections; the inline lossless floor)
- **language:** en
- **size:** 8458 bytes / not-yet-measured tokens  (baseline: 11595 B, −3137 B / −27.1%)

## How it was made
Baseline compressed to its densest *lossless* form: telegraphic bold-header sections (`**SESSION FIRST**`, `**FRUGAL**`, `**CMDS**`, `**ARCH**`), maximal abbreviation and symbol use, all articles/copulas dropped — but every fact retained inline, including the full command semantics and the secrets cheatsheet compacted rather than moved. This is the floor of inline losslessness: below this size, savings require *moving* reference material (level 4) or *dropping* it (level 5). Prose typos fixed; `protocol/` → `protocols/` with the four governance docs listed. Trinity clause ADDED with the verbatim two-line block.

## Alterations to raise eval scores
- none yet

## Loss ledger
> Lossless. Densest inline form; nothing dropped or moved.

| what | why (method / level / vs intent) | recoverable-where |
|------|----------------------------------|-------------------|
| Trinity clause (2-line block) | *(protected)* — ADDED, verbatim | kept inline, verbatim |
| Session-first flow + `Session.Create` block + env-var non-expansion rule | *(protected)* — inline verbatim | kept inline, verbatim |
| Terragrunt port-forward prereq + KUBE_*/AWS_* exports | *(protected)* — inline | kept inline, verbatim |
| Full secrets cheatsheet + all command syntax | *(protected)* — compacted inline, NOT moved | kept inline, verbatim |
| — (no baseline fact dropped) | level 3 — telegraphic, lossless floor | kept inline |

Coreference / omission flags: none — telegraphic register is pronoun-free; symbol/abbreviation legend assumed unambiguous to target model.

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
Why it exists: the empirical inline-lossless floor for this file — the reference point proving that everything below ~8.5KB in the corpus is bought by *reference* (pointer-index-c4, npl-ref-c4) or *loss* (ultra-terse-lossy-c5, spr-priming-c5), not by tighter inline phrasing. Prefer it when you want the smallest prompt that still carries every fact verbatim with no external read. Weakness: dense to the point of low human readability; heavy on notation.
