# shorthand-trinity-c2.meta.md — variant meta + loss ledger

## Variant
- **slug:** shorthand-trinity-c2
- **derived from:** shorthand-c2
- **compactness level:** 2
- **style:** shorthand (English abbreviations + logic symbols ⇒ ∀ ¬)
- **language:** en
- **size:** 10575 bytes / not-yet-measured tokens  (baseline: 11595 B, −1020 B / −8.8%; vs shorthand-c2 10038 B, +537 B)

## How it was made
Exact copy of `shorthand-c2` plus two changes: (1) a new `## Runtime Protocol — Trinity (REQUIRED)` section added near the top (after FIRST ACTION) with a one-line 3-phase gloss above the verbatim two-line Trinity block; (2) the stale `protocol/` Key-Dirs entry corrected to `protocols/` and expanded to list all four governance docs. Nothing else differs from the pin.

## Alterations to raise eval scores
- none yet

## Loss ledger
> Lossless. The only content delta vs shorthand-c2 is an ADDITION (Trinity) + a stale-ref correction.

| what | why (method / level / vs intent) | recoverable-where |
|------|----------------------------------|-------------------|
| Trinity clause (2-line block) | *(protected)* — ADDED near top, verbatim English | kept inline, verbatim |
| `protocol/` → `protocols/` (+ 4 governance docs) | correction of baseline's stale singular dir ref | kept inline |
| — (no baseline fact dropped) | level 2 — shorthand restyle, lossless | kept inline |

Coreference / omission flags: none.

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
The **trinity-bearing twin of the live pin.** This is the promotion target when Trinity should go live at the repo root: `ln -sfn .claude/CLAUDE.md/shorthand-trinity-c2.md CLAUDE.md` (or set `pin: shorthand-trinity-c2` in `CLAUDE.md.prompt`). It reproduces the exact style the repo currently runs, so promoting it changes behavior only by adding the Trinity obligation and fixing the `protocols/` reference — no other drift. Until then it sits as an un-promoted candidate.
