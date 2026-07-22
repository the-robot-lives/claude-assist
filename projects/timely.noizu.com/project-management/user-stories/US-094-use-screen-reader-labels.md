---
id: US-094
title: "Use screen reader labels"
slug: use-screen-reader-labels
personas: [P-007]
epic: "Accessibility, Reliability & Edge Cases"
priority: should-have
complexity: medium
tags: [accessibility, reliability]
---

# US-094: Use screen reader labels

## User Story

**As a** Timely user in an edge condition  
**I want to** hear meaningful labels for charts, intervals, and controls  
**So that** review time non-visually

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
