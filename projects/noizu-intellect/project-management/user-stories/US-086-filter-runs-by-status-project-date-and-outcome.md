---
id: US-086
title: "Filter runs by status, project, date, and outcome"
slug: filter-runs-by-status-project-date-and-outcome
personas: [P-001, P-005]
epic: "Search & Discovery"
priority: must-have
complexity: medium
tags: [search, filtering, path-execution, runs]
---

# US-086: Filter Runs by Status, Project, Date, and Outcome

## User Story

**As a** solo staff engineer (Devon Reyes) reviewing my history of parallel-path runs
**I want to** filter the run list by status, project, date range, and outcome
**So that** I can quickly find the runs I care about instead of scrolling a flat chronological list

## Acceptance Criteria

- **Given** the run list view
  **When** I apply a status filter (e.g. in-progress, completed, failed, timed out)
  **Then** only runs matching that status appear, and the filter is reflected in a shareable URL/query state

- **Given** multiple projects the user has access to
  **When** I filter by project
  **Then** the run list scopes to that project only, and combining it with other filters (status, date, outcome) narrows further with AND semantics

- **Given** a date range filter
  **When** applied
  **Then** runs are filtered by their creation (or completion) timestamp, with sensible presets (today, last 7 days, last 30 days) plus a custom range picker

- **Given** an outcome filter (e.g. "winning path selected", "no viable path", "abandoned")
  **When** applied
  **Then** it filters on the recorded pick/reward outcome of the run, not merely its execution status

## Notes
Outcome filtering depends on the pick/reward record produced once a human or Picker agent selects a winning path. Complements [[US-084]] global search — this is structured filtering rather than free-text lookup, and the two should share the same result-list UI component where practical.
