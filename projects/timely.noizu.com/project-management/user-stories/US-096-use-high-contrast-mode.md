---
id: US-096
title: "Use high contrast mode"
slug: use-high-contrast-mode
personas: [P-007, P-005]
epic: "Accessibility, Reliability & Edge Cases"
priority: should-have
complexity: medium
tags: [accessibility, reliability]
---

# US-096: Use high contrast mode

## User Story

**As a** Timely user in an edge condition  
**I want to** use a contrast-safe interface  
**So that** read dense timelines clearly

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
