# Compactness Scale — Reference Card

The `compactness` axis, 0–5. Leveled like verbosity, but every level names a **known, declared sacrifice** — there is no free compression. Levels 0–3 are lossless (all facts inline). Level 4 is lossless *by reference* (facts moved to verified pointers). Level 5 is lossy (facts dropped, ledgered).

| Level | Name | Lossless? | Reversible |
|-------|------|-----------|-----------|
| 0 | Verbatim | yes (it's the original) | n/a |
| 1 | Edited-lossless | yes | fully — nothing dropped but noise |
| 2 | Shorthand-lossless | yes | fully — expand the notation |
| 3 | Dense-lossless floor | yes | fully — all facts present |
| 4 | Lossless-by-reference | by reference | by fetching the pointed-at doc/element |
| 5 | Telegraphic-lossy | no | only from the baseline / ledger |

---

## Per-level sacrifice statements

State the matching line to the caller when you deliver a variant at that level.

- **Level 0 — Verbatim.** "No changes; the original bytes, typos and all. Sacrifice: nothing, and no savings."
- **Level 1 — Edited-lossless.** "Full words, no notation. I removed redundancy, hedging, and filler. Sacrifice: none of the facts — only the noise. Everything is recoverable because nothing meaningful left."
- **Level 2 — Shorthand-lossless.** "Abbreviations and symbols substituted for common words/relations, with a legend. Sacrifice: readability for someone unfamiliar with the notation. Reversible by expanding the shorthand. (Measure the token delta — some notation tokenizes *longer* under BPE.)"
- **Level 3 — Dense-lossless floor.** "Telegraphic sections, all facts retained inline. This is the floor for 'everything inline, nothing lost.' Sacrifice: prose flow and explanatory rationale. Past here, more size means moving reference out, not deleting facts."
- **Level 4 — Lossless-by-reference.** "Behavioral rules kept inline; reference material replaced by one-line denotations + verified pointers (docs / NPLLoad). Sacrifice: one fetch per referenced area at use time. No fact is lost — its location changed. Every pointer was verified to resolve before shipping."
- **Level 5 — Telegraphic-lossy.** "Only what the declared intent needs survives; named facts were dropped (see the loss ledger). Sacrifice: those facts, recoverable **only** from the baseline. Reach here only when the caller accepted loss in a `lossy_ok` area — and note that level 4 usually reaches the same size without the loss."

---

## The 3→4 rule (the one to remember)

Style compression bottoms out around level 3. Further size comes from **moving reference material out (level 4), not deleting facts (level 5).** In the CLAUDE.md worked example, level 5 (3.9KB) landed slightly larger than level 4 (3.8KB) while dropping ~4.2KB of facts — a strictly worse trade. **Reach for level 4 before level 5.** Only go lossy when loss is explicitly authorized.

## Protected facts are level-independent

Anything on the `protect` list survives **verbatim at every level, including 5.** Protected commands, exact numbers, and hard rules are copied through and never paraphrased, abbreviated, moved, or dropped. If a protected fact can't fit the token budget, report the overage — do not compress it to fit.

## Mapping to the CLAUDE.md corpus

| Level | Corpus variant | Size |
|-------|---------------|------|
| 0 | baseline-original | 11.6KB |
| 1 | plain-english-concise | 11.1KB |
| 2 | shorthand-symbolic (live) / structured-data | 10.0 / 9.9KB |
| 3 | checklist-imperative / ultra-terse-min-loss | 9.5 / 8.1KB |
| 4 | pointer-index | 3.8KB |
| 5 | ultra-terse-lossy | 3.9KB (~4.2KB facts dropped) |
