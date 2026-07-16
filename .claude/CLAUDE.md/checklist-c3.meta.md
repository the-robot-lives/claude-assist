# checklist-c3.meta.md — variant meta + loss ledger

## Variant
- **slug:** checklist-c3
- **derived from:** baseline
- **compactness level:** 3
- **style:** checklist (MUST/MUST-NOT rules as a flat compliance-ordered checklist; reference after)
- **language:** en
- **size:** 10011 bytes / not-yet-measured tokens  (baseline: 11595 B, −1584 B / −13.7%)

## How it was made
Baseline reorganized rules-first: behavioral obligations pulled to the top as a numbered `MUST` checklist in compliance-priority order, reference material (commands, architecture) following after. The real win here is reliability — rules can't hide inside paragraphs. Prose typos fixed; `protocol/` → `protocols/` with the four governance docs listed. Trinity clause ADDED (new requirement) as a high-priority `MUST` checklist item with the verbatim two-line block.

## Alterations to raise eval scores
- none yet

## Loss ledger
> Lossless reordering. Nothing dropped or moved.

| what | why (method / level / vs intent) | recoverable-where |
|------|----------------------------------|-------------------|
| Trinity clause (2-line block) | *(protected)* — ADDED as top `MUST` item, verbatim | kept inline, verbatim |
| Session-first flow + `Session.Create` block + env-var non-expansion rule | *(protected)* — first `MUST`, inline verbatim | kept inline, verbatim |
| Terragrunt port-forward prereq + KUBE_*/AWS_* exports | *(protected)* — inline | kept inline, verbatim |
| All command syntax | *(protected)* — verbatim in reference section | kept inline, verbatim |
| — (no baseline fact dropped) | level 3 — reorder + telegraphic checklist, lossless | kept inline |

Coreference / omission flags: none — imperative checklist phrasing removes most pronouns.

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
Why it exists: tests rule-first ordering as a compliance lever — the hypothesis that a model obeys a prompt more reliably when the MUST rules lead and reference trails. Prefer it when instruction-following is the priority over reading flow. Weakness: separating rules from their context can strand a rule from the detail that makes it actionable; the reference section must stay findable.
