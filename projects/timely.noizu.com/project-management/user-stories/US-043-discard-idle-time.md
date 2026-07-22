---
id: US-043
title: "Discard idle time"
slug: discard-idle-time
personas: [P-001, P-006]
epic: "Idle & Resumption Intelligence"
priority: must-have
complexity: medium
tags: [idle, resumption]
---

# US-043: Discard idle time

## User Story

**As a** interrupted user  
**I want to** discard idle time from billable records  
**So that** avoid charging for away time

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
