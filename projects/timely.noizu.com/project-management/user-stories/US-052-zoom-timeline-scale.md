---
id: US-052
title: "Zoom timeline scale"
slug: zoom-timeline-scale
personas: [P-001]
epic: "Timeline Review & Analytics"
priority: should-have
complexity: medium
tags: [review, analytics]
---

# US-052: Zoom timeline scale

## User Story

**As a** reviewing user  
**I want to** zoom from full day to minute-level detail  
**So that** inspect dense task switches

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
