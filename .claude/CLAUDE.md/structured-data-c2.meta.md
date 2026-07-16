# structured-data-c2.meta.md — variant meta + loss ledger

## Variant
- **slug:** structured-data-c2
- **derived from:** baseline
- **compactness level:** 2
- **style:** yaml-meta (rules & facts recast as YAML blocks; prose minimized, commands consolidated)
- **language:** en
- **size:** 10612 bytes / not-yet-measured tokens  (baseline: 11595 B, −983 B / −8.5%)

## How it was made
Baseline recast into machine-parseable framing: rules and facts expressed as nested YAML keys (`rules:`, `dirs:`, `tiers:`, etc.), narrative prose minimized, command references consolidated into blocks. Tests whether a declarative, diffable structure holds instruction compliance as well as prose. Prose typos fixed; `protocol/` → `protocols/` with the four governance docs listed. Trinity clause ADDED (new requirement) as a top-level structured rule entry with the verbatim two-line block.

## Alterations to raise eval scores
- none yet

## Loss ledger
> Lossless restructure. Nothing dropped or moved.

| what | why (method / level / vs intent) | recoverable-where |
|------|----------------------------------|-------------------|
| Trinity clause (2-line block) | *(protected)* — ADDED as structured rule, verbatim | kept inline, verbatim |
| Session-first flow + `Session.Create` block + env-var non-expansion rule | *(protected)* — inline, verbatim | kept inline, verbatim |
| Terragrunt port-forward prereq + KUBE_*/AWS_* exports | *(protected)* — inline | kept inline, verbatim |
| All command syntax | *(protected)* — verbatim in consolidated blocks | kept inline, verbatim |
| — (no baseline fact dropped) | level 2 — restructure, lossless | kept inline |

Coreference / omission flags: prose pronouns resolved to explicit YAML keys during restructure. No borderline omissions.

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
Why it exists: probes whether a config-shaped prompt (declarative keys, easily machine-diffed) is followed as reliably as prose, and whether structure aids fact recall. Prefer it when the file will be consumed/patched programmatically. Weakness: YAML nesting adds punctuation overhead; a deeply structured prompt can read as data rather than instruction to some models.
