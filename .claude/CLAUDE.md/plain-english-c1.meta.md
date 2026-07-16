# plain-english-c1.meta.md — variant meta + loss ledger

## Variant
- **slug:** plain-english-c1
- **derived from:** baseline
- **compactness level:** 1
- **style:** plain (full words, complete sentences — no symbols or abbreviations)
- **language:** en
- **size:** 11708 bytes / not-yet-measured tokens  (baseline: 11595 B, +113 B / +1.0%)

## How it was made
Ruthless plain-English edit of the baseline: redundancy, filler, and hedging removed while every word stays a full word (no `b4`/`w/`/`⇒`). Tests concision *without* notation — the level-1 lossless floor. Prose typos fixed; the stale `protocol/` Key-Dirs entry corrected to `protocols/` and expanded to list the four governance docs. The Trinity clause was ADDED (new requirement, absent from baseline) as a plain-prose rule with the verbatim two-line block. The +1.0% over baseline reflects that Trinity is net-new content the baseline never carried — the plain-English edit itself is slightly under baseline before that addition.

## Alterations to raise eval scores
- none yet

## Loss ledger
> Lossless. Filler removed is not fact; Trinity is an addition.

| what | why (method / level / vs intent) | recoverable-where |
|------|----------------------------------|-------------------|
| Trinity clause (2-line block) | *(protected)* — ADDED, verbatim English | kept inline, verbatim |
| Session-first flow + `Session.Create` block + env-var non-expansion rule | *(protected)* — inline, verbatim | kept inline, verbatim |
| Terragrunt port-forward prereq + KUBE_*/AWS_* exports | *(protected)* — inline | kept inline, verbatim |
| All command syntax (`dc`/`secret-bucket`/`docker-*`/`helm-upgrade`/`deploy-service`/`terragrunt`) | *(protected)* — verbatim | kept inline, verbatim |
| redundancy / filler / hedging | level 1 — not fact; removed | n/a (stylistic) |

Coreference / omission flags: baseline pronouns ("hang off it", "use that bucket") resolved to explicit nouns during the edit. No borderline omissions.

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
Why it exists: the readable end of the corpus — the most concise version that still reads as ordinary English, for maintainers who will edit the file by hand and dislike notation. Weakness: barely smaller than baseline; if token budget matters, pick a shorthand or terser variant. Prefer it when human editability and zero-ambiguity phrasing outrank size.
