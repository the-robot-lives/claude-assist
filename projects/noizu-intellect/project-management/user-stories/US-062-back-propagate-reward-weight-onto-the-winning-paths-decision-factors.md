---
id: US-062
title: "Back-propagate reward weight onto the winning path's decision factors"
slug: back-propagate-reward-weight-onto-the-winning-paths-decision-factors
personas: [P-005, P-001]
epic: "Review & Reward"
priority: must-have
complexity: high
tags: [reward, decision-weights, planner, back-propagation]
---

# US-062: Back-Propagate Reward Weight Onto the Winning Path's Decision Factors

## User Story

**As a** researcher (Dr. Elias Thorn) studying whether the system actually improves its planning over time
**I want to** have a confirmed pick automatically increase the weight of the decision factors that led to the winning path
**So that** future plan decompositions are more likely to favor approaches that have historically won

## Acceptance Criteria

- **Given** a finalized pick for a run
  **When** back-propagation runs
  **Then** every decision factor recorded along the winning path (the branch points chosen at each tag/checkout, model selections, sub-agent assignments) receives a positive weight update in the decision-weight store, and losing paths' factors receive no update (or a smaller/negative one if configured)

- **Given** a weight update
  **When** it is applied
  **Then** it is recorded as a discrete, timestamped entry in the decision-weight history (not an in-place overwrite) so the change is auditable and reversible

- **Given** a decision factor that appears along both a winning and a losing path in the same run
  **When** weights are updated
  **Then** the system applies a documented resolution rule (e.g. net effect, or no-op) rather than an undefined double-update

## Notes
This is the core learning loop mechanic of the product. Weight updates must be visible in [[US-063]] and must respect the freeze toggle in [[US-064]]. Should reference the specific decision factors captured during the Plan pass of each path's turn pipeline, not the full transcript.
