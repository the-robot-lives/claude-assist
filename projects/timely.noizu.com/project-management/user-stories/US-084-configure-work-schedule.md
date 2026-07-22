---
id: US-084
title: "Configure work schedule"
slug: configure-work-schedule
personas: [P-003, P-004]
epic: "Workspace Administration"
priority: could-have
complexity: medium
tags: [admin, workspace]
---

# US-084: Configure work schedule

## User Story

**As a** workspace admin  
**I want to** set expected work hours and days  
**So that** interpret idle and after-hours work

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
