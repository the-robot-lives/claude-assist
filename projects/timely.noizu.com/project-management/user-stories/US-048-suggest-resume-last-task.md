---
id: US-048
title: "Suggest resume last task"
slug: suggest-resume-last-task
personas: [P-004, P-007]
epic: "Idle & Resumption Intelligence"
priority: must-have
complexity: medium
tags: [idle, resumption]
---

# US-048: Suggest resume last task

## User Story

**As a** interrupted user  
**I want to** offer to resume the previous task  
**So that** restart quickly

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
