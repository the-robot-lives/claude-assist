---
id: US-061
title: "Reject all outcomes and request a re-plan"
slug: reject-all-outcomes-and-request-a-re-plan
personas: [P-001, P-003]
epic: "Review & Reward"
priority: should-have
complexity: medium
tags: [rejection, re-plan, path-execution]
---

# US-061: Reject All Outcomes and Request a Re-Plan

## User Story

**As a** staff engineer (Devon Reyes) reviewing a shortlist where none of the paths actually solve the problem
**I want to** reject all outcomes instead of being forced to pick a winner
**So that** the Planner gets a signal to produce a new decomposition rather than rewarding a mediocre path by default

## Acceptance Criteria

- **Given** a graded shortlist of completed paths
  **When** I choose "reject all" instead of picking a winner
  **Then** no reward back-propagation occurs, no path's memory is written back, and the run is marked as rejected rather than completed

- **Given** a rejection
  **When** I confirm it
  **Then** I am prompted for a short reason (free text) that is stored with the rejection and made available to the Planner for the next attempt

- **Given** a rejected run
  **When** the Planner is re-invoked for the same original request
  **Then** it receives the rejection reason and the prior paths' grades as context so the new plan can avoid repeating the same failure mode

## Notes
Rejection is distinct from a low-scoring pick — it produces zero reward signal. Should appear as its own outcome type in decision history ([[US-065]]) so patterns of repeated rejection are visible to Sam Okafor's team.
