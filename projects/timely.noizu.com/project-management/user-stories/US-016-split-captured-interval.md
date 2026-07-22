---
id: US-016
title: "Split captured interval"
slug: split-captured-interval
personas: [P-001, P-004]
epic: "Core Tracking & Evidence"
priority: must-have
complexity: medium
tags: [tracking, timeline]
---

# US-016: Split captured interval

## User Story

**As a** daily user  
**I want to** split a long interval into smaller task blocks  
**So that** correct mixed work after the fact

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
