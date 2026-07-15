---
id: US-090
title: "Submit and poll a run via the API"
slug: submit-and-poll-a-run-via-the-api
personas: [P-005, P-001]
epic: "Integration & API"
priority: must-have
complexity: medium
tags: [api, runs, parallel-paths]
---

# US-090: Submit and Poll a Run via the API

## User Story

**As a** researcher working API-first
**I want to** submit a parallel-path run request via a REST/JSON API call and poll its status until paths complete and a pick is made
**So that** I can drive runs from my own scripts and notebooks without going through the chat UI

## Acceptance Criteria

- **Given** I have an API credential scoped to a project
  **When** I POST a run request with a prompt, project id, and optional decomposition/tier constraints
  **Then** the API returns a run id immediately and enqueues the Planner decomposition asynchronously

- **Given** a run id from a prior submission
  **When** I GET the run status endpoint
  **Then** the response includes overall run state (planning/executing/reviewing/picked/failed), per-path state, and per-path token spend, refreshed to reflect the latest DB state on each poll

- **Given** a run has completed and a pick has been made
  **When** I GET the run
  **Then** the response includes the winning path's full turn history, the Reviewer's grade, and the pick rationale if one was recorded

- **Given** I submit a run request with invalid parameters (unknown project id, malformed prompt, invalid tier)
  **When** the API processes it
  **Then** it returns a structured 4xx error identifying the invalid field, and no run is enqueued

## Notes
This is the foundation Elias (P-005) needs before any of the other Integration & API stories — webhooks ([[US-091]]), scripted experiments ([[US-092]]), and bulk export ([[US-093]]) all assume runs can be submitted and read back programmatically. Should expose the same run/path/pick data model the chat UI uses, not a parallel shadow representation.
