---
id: US-060
title: "Pick a winner with a one-line rationale"
slug: pick-a-winner-with-a-one-line-rationale
personas: [P-004, P-001]
epic: "Review & Reward"
priority: must-have
complexity: low
tags: [picking, rationale, decision-history]
---

# US-060: Pick a Winner With a One-Line Rationale

## User Story

**As a** human picker (Priya Natarajan or Devon Reyes) reviewing a comparison view
**I want to** select one path as the winner and record a short one-line rationale for the choice
**So that** the decision is captured alongside the outcome for future audits and for the reward signal to reference

## Acceptance Criteria

- **Given** a comparison view with 2+ shortlisted paths
  **When** I select one path as the winner
  **Then** I am prompted for a required one-line rationale (free text, capped length) before the pick is finalized

- **Given** a finalized pick
  **When** the pick is saved
  **Then** it is recorded as versioned content tied to the run, the winning path, and the picker's identity, and immediately triggers reward back-propagation ([[US-062]]) and memory write-back ([[US-067]])

- **Given** a pick that has already been made for a run
  **When** I attempt to pick again
  **Then** the system either blocks the change or requires an explicit "revise pick" action that preserves the original pick in history rather than silently overwriting it

## Notes
The one-line rationale is what shows up later in decision history ([[US-065]]) and weight-history views ([[US-063]]) — keep it short and always required, since it's the human-readable justification agents and auditors will rely on.
