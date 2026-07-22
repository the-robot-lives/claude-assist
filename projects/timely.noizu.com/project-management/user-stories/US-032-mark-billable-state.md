---
id: US-032
title: "Mark billable state"
slug: mark-billable-state
personas: [P-001, P-004, P-007]
epic: "Core Tracking & Evidence"
priority: must-have
complexity: medium
tags: [tracking, timeline]
---

# US-032: Mark billable state

## User Story

**As a** daily user  
**I want to** set billable, non-billable, or internal status  
**So that** prepare reporting

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
