---
id: US-014
title: "Track overlapping task"
slug: track-overlapping-task
personas: [P-001, P-004, P-007]
epic: "Core Tracking & Evidence"
priority: must-have
complexity: medium
tags: [tracking, timeline]
---

# US-014: Track overlapping task

## User Story

**As a** daily user  
**I want to** add a concurrent task over an existing interval  
**So that** model parallel responsibility windows

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
