---
id: US-063
title: "View decision-weight history and its effect on planning"
slug: view-decision-weight-history-and-its-effect-on-planning
personas: [P-005]
epic: "Review & Reward"
priority: should-have
complexity: medium
tags: [decision-weights, history, research, api]
---

# US-063: View Decision-Weight History and Its Effect on Planning

## User Story

**As a** researcher (Dr. Elias Thorn) running controlled experiments on the planning loop
**I want to** inspect the full history of decision-weight updates for a project, including when each update happened and which pick caused it
**So that** I can trace how the reward signal has shifted planner behavior over time and correlate it with plan quality

## Acceptance Criteria

- **Given** a project with multiple completed runs and picks
  **When** I query the decision-weight history via the API
  **Then** I receive a time-ordered list of weight update entries, each linked to the triggering pick, the affected decision factor, and the before/after weight values

- **Given** a specific decision factor (e.g. "prefer model X for refactor tasks")
  **When** I filter the history to that factor
  **Then** I can see its weight trajectory across all runs that touched it, isolated from unrelated factors

- **Given** a weight history query over a date range
  **When** I request it programmatically
  **Then** the response is structured data (not just a rendered UI view) suitable for offline statistical analysis

## Notes
API-first per P-005's persona profile. Pairs with [[US-074]] (full run export) for reproducible experiments. The UI view is a nice-to-have on top of the API; the API is the must-have surface.
