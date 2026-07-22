---
id: US-097
title: "Handle long task names"
slug: handle-long-task-names
personas: [P-001, P-006]
epic: "Accessibility, Reliability & Edge Cases"
priority: must-have
complexity: medium
tags: [accessibility, reliability]
---

# US-097: Handle long task names

## User Story

**As a** Timely user in an edge condition  
**I want to** display long client and task names without layout breakage  
**So that** avoid unreadable reports

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
