---
id: P-009
name: "Rosa Jimenez"
slug: rosa-jimenez
archetype: "Cost-conscious hobbyist on constrained resources"
segment: edge-case
tags: [hobbyist, budget, low-bandwidth, local-models]
---

# P-009: Rosa Jimenez

## Demographics

| Attribute | Value |
|-----------|-------|
| Age | 24 |
| Occupation | CS student & indie game developer |
| Location | Oaxaca, Mexico |
| Tech comfort | Medium-high |

## Bio
Rosa runs Noizu Intellect on a home server with a mix of small local models and a strictly rationed cloud-API budget. Her internet is intermittent. Parallel-path execution is exactly what she can't afford to do carelessly — she needs the system to be frugal by default and honest about cost.

## Goals
- See estimated token/cost before launching a multi-path run, and cap it
- Route routine turns to cheap/local models, reserving paid models for judging and finals
- Keep working through connection drops without losing run state

## Frustrations
- Fan-out features with no price tag until the bill arrives
- UIs that assume always-on broadband and stream heavy payloads
- Being locked out of "pro" workflows just because she optimizes for cost

## Behaviors
- Sets hard budgets and watches spend meters
- Batches work for when her connection is good
- Favors 2 well-chosen paths over 8 speculative ones

## Job to Be Done
> "When I want parallel-path power on a student budget, I want per-run cost estimates, cheap-model routing, and resilience to flaky connectivity, so I can use the real workflow without financial or network surprises."

## Relationship to Product
Small self-hosted org; heavy user of model-selection constraints (`fastest`, `cheapest`), run cost preview/caps, and offline-tolerant, low-bandwidth UI modes.

## Scenarios
- **Scenario 1:** Budget run — Rosa previews a 3-path run estimated at 120k tokens, trims to 2 paths on her local model with a cloud model only for the grade step.
- **Scenario 2:** Dropped link — her connection dies mid-run; paths continue server-side and the UI reconciles cleanly when she reconnects.
