---
id: US-036
title: "Undo timeline edit"
slug: undo-timeline-edit
personas: [P-001, P-004]
epic: "Core Tracking & Evidence"
priority: should-have
complexity: medium
tags: [tracking, timeline]
---

# US-036: Undo timeline edit

## User Story

**As a** daily user  
**I want to** undo the last correction  
**So that** edit without fear

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
