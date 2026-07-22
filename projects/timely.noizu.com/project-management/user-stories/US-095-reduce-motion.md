---
id: US-095
title: "Reduce motion"
slug: reduce-motion
personas: [P-007]
epic: "Accessibility, Reliability & Edge Cases"
priority: should-have
complexity: medium
tags: [accessibility, reliability]
---

# US-095: Reduce motion

## User Story

**As a** Timely user in an edge condition  
**I want to** disable nonessential motion  
**So that** avoid distraction or discomfort

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
