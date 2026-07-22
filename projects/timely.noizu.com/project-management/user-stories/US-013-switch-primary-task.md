---
id: US-013
title: "Switch primary task"
slug: switch-primary-task
personas: [P-001, P-004]
epic: "Core Tracking & Evidence"
priority: must-have
complexity: medium
tags: [tracking, timeline]
---

# US-013: Switch primary task

## User Story

**As a** daily user  
**I want to** switch the primary task without ending secondary work  
**So that** represent context changes cleanly

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
