---
id: US-093
title: "Keyboard navigate timeline"
slug: keyboard-navigate-timeline
personas: [P-007]
epic: "Accessibility, Reliability & Edge Cases"
priority: must-have
complexity: medium
tags: [accessibility, reliability]
---

# US-093: Keyboard navigate timeline

## User Story

**As a** Timely user in an edge condition  
**I want to** operate timeline review without a mouse  
**So that** support fast and accessible correction

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
