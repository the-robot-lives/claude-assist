---
id: P-005
name: "Dr. Elias Thorn"
slug: elias-thorn
archetype: "Multi-agent systems researcher"
segment: secondary
tags: [researcher, evaluation, data-export, meta-planner]
---

# P-005: Dr. Elias Thorn

## Demographics

| Attribute | Value |
|-----------|-------|
| Age | 45 |
| Occupation | Applied AI researcher, independent lab |
| Location | Berlin, Germany |
| Tech comfort | High |

## Bio
Elias studies how plan decomposition and reward feedback shape multi-agent performance. Noizu Intellect's decision-weight store and execution trees are his experimental substrate: he runs controlled comparisons, inspects the tree, and exports everything for offline analysis.

## Goals
- Run repeatable experiments: same request, varied decomposition strategies or models, measured outcomes
- Inspect the full execution tree — every path, turn, grade, and discarded branch
- Export runs (messages, plans, grades, weight updates) as structured data

## Frustrations
- Systems that discard losing paths without a trace
- Non-determinism he can't control or at least record
- APIs that expose chat but hide the planner's decision factors

## Behaviors
- Scripts everything against the API; the UI is for spot-checks
- Cares about provenance: model versions, prompt versions, seeds, timestamps
- Publishes findings, so needs clean anonymized exports

## Job to Be Done
> "When I hypothesize that a planning strategy is better, I want to run instrumented parallel-path experiments and export the evidence, so I can measure — not guess — what improves outcomes."

## Relationship to Product
API-first power user of path execution, tree inspection, decision-weight history, and bulk export. Stress-tests exactly the surfaces casual users never open.

## Scenarios
- **Scenario 1:** Ablation — Elias runs 20 identical requests with reward-backprop enabled and 20 with it frozen, exports grades, and compares pick quality over time.
- **Scenario 2:** Tree autopsy — after a surprising winner, Elias walks the losing branches turn-by-turn to find where they went wrong.
