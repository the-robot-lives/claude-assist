---
id: US-078
title: "View token spend by agent, run, and user"
slug: view-token-spend-by-agent-run-and-user
personas: [P-006]
epic: "Admin & Platform Ops"
priority: should-have
complexity: medium
tags: [reporting, token-accounting, spend]
---

# US-078: View Token Spend by Agent, Run, and User

## User Story

**As a** self-hosting admin/SRE
**I want to** view a breakdown of token spend grouped by agent, by parallel-path run, and by originating human user
**So that** I can identify which agents, runs, or users are driving cost and act on it

## Acceptance Criteria

- **Given** token accounting data exists for a project
  **When** I open the spend report and group by agent
  **Then** I see total tokens and estimated cost per agent, broken down further by provider/model tier used

- **Given** I select a specific run
  **When** I drill into it
  **Then** I see per-path token spend, which path was picked, and the model tier each path executed against

- **Given** I filter the report by date range and by originating user
  **When** the filter is applied
  **Then** totals recompute to reflect only turns whose triggering message or run was attributed to that user

- **Given** a run included paths that were capped or errored out (see [[US-077]])
  **When** I view that run's spend
  **Then** capped/errored paths are shown with their partial spend, clearly flagged as non-winning and non-graded

## Notes
Underpins budget alerting in [[US-077]] and gives Nadia (P-006) the evidence to justify tier/provider changes ([[US-076]]). Should reuse the same token-accounting rows Oban queue workers write during path execution.
