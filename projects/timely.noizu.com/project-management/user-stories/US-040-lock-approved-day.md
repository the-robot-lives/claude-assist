---
id: US-040
title: "Lock approved day"
slug: lock-approved-day
personas: [P-001, P-004]
epic: "Core Tracking & Evidence"
priority: should-have
complexity: medium
tags: [tracking, timeline]
---

# US-040: Lock approved day

## User Story

**As a** daily user  
**I want to** lock a reviewed day against casual edits  
**So that** preserve billing integrity

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
