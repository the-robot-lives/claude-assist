---
id: US-039
title: "Submit a request for parallel-path decomposition"
slug: submit-a-request-for-parallel-path-decomposition
personas: [P-001]
epic: "Parallel-Path Execution"
priority: must-have
complexity: medium
tags: [planner, decomposition, path-launch]
---

# US-039: Submit a Request for Parallel-Path Decomposition

## User Story

**As a** solo staff engineer
**I want to** submit a task to the Planner and have it propose a decomposition into N independent solution paths before anything runs
**So that** I get several genuinely different attempts at my problem instead of committing to one agent's first idea

## Acceptance Criteria

- **Given** I post a request in a channel and address it to the Planner (`@planner`, confidence 100)
  **When** the Planner completes its Plan pass
  **Then** it returns a proposed breakdown of N candidate paths, each with a short rationale for how it differs from the others, without launching any path yet

- **Given** the Planner has produced a proposed breakdown
  **When** I take no action
  **Then** no path GenServers are started and no model calls beyond the Planner's own turn are billed

- **Given** my request is ambiguous or under-specified
  **When** the Planner processes it
  **Then** it asks a clarifying question in-channel instead of guessing a decomposition, and waits for my reply before proposing paths

- **Given** the Planner proposes a breakdown
  **When** I inspect it
  **Then** each candidate path shows which shared base context checkpoint it will fork from (see US-044) and which agent(s) are assigned

## Notes
This is the entry point to the product's signature mechanic — everything downstream (US-040 through US-056) operates on the breakdown this story produces. The Planner's proposal is itself a versioned message so later grading can compare actual outcomes back to the stated rationale for each path.
