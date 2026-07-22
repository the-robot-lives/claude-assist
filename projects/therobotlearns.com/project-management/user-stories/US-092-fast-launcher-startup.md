---
id: US-092
title: "Fast launcher startup"
slug: fast-launcher-startup
personas: [P-003, P-001]
epic: "Performance & Scale"
priority: should-have
complexity: medium
tags: [performance, startup, cli]
---

# US-092: Fast Launcher Startup

## User Story

**As an** SRE/DevOps polymath with a huge knowledge base
**I want to** have the robot-learns launcher start in under 2 seconds
**So that** I don't lose focus context-switching into a daily learning session

## Acceptance Criteria

- **Given** a KB with thousands of entries
  **When** `robot-learns` is launched
  **Then** the agent environment bootstraps and is ready for input in under 2 seconds

- **Given** the launcher is started repeatedly
  **When** comparing cold start versus warm start (cached state)
  **Then** warm start is faster than cold start, and both meet the sub-2-second target

- **Given** startup exceeds the 2-second budget
  **When** this occurs
  **Then** a startup timing diagnostic is available to identify the bottleneck

## Notes
Applies equally to daily learners (P-001) who launch the tool frequently throughout the day.
