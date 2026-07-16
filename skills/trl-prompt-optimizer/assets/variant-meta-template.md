# {slug}.meta.md — variant meta + loss ledger template
# One per variant, beside .{name}.md/{slug}.md. Fill the < > slots.

## Variant
- **slug:** <slug, e.g. pointer-index-c4>
- **derived from:** <baseline | other-slug>
- **compactness level:** <0-5>
- **style:** <plain | shorthand | yaml-meta | mermaid | pure-npl | checklist | pointer-index | pseudo-code>
- **language:** <en | ...>
- **size:** <bytes> / <tokens on target tokenizer>  (baseline: <bytes>/<tokens>, <−X%>)

## How it was made
<2-4 sentences: which compression methods and/or style transform were applied, in what order.
 Note any coreference resolutions and any reordering. Reference compression-methods.md method numbers
 where useful.>

## Alterations to raise eval scores
- <change made after a low score, and which case it fixed — or "none yet">

## Loss ledger
> Every fact dropped or MOVED. Protected facts never appear here as dropped.
> "Moved" requires a VERIFIED recoverable-where. Level-5 drops are recoverable only from the baseline.

| what | why (method / level / vs intent) | recoverable-where |
|------|----------------------------------|-------------------|
| <fact / span / section> | <e.g. level 4: reference material, moved> | <docs/… (verified) | NPLLoad X@tier (verified) | DROPPED — baseline only> |

Coreference / omission flags: <pronouns resolved, borderline omissions — or "none">

## Eval  (dataset: <spec file>, run <date>)
| case id | criterion outcomes | pass? |
|---------|--------------------|-------|
| <id> | <criterion: score, ...> | ✅/❌ |

- **Aggregate:** <0-1> (threshold <t>)
- **required_pass:** <all clear | which failed>
- **token_cost:** <n>
- **reject_if hits:** <none | phrase>

## Adhoc evals
- <case not in the standing dataset, why it was run, outcome. Promote generally-useful ones into the spec.>

## Notes
<anything a future maintainer needs: why this variant exists, when to prefer it, known weaknesses.>
