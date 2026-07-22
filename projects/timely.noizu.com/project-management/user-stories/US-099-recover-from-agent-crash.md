---
id: US-099
title: "Recover from agent crash"
slug: recover-from-agent-crash
personas: [P-001, P-004]
epic: "Accessibility, Reliability & Edge Cases"
priority: must-have
complexity: medium
tags: [accessibility, reliability]
---

# US-099: Recover from agent crash

## User Story

**As a** Timely user in an edge condition  
**I want to** recover capture state and warn about gaps  
**So that** avoid silent data loss

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
