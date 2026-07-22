---
id: US-086
title: "Connect calendar"
slug: connect-calendar
personas: [P-001, P-003, P-004]
epic: "Integrations & API"
priority: should-have
complexity: medium
tags: [integration, api]
---

# US-086: Connect calendar

## User Story

**As a** integrated workflow user  
**I want to** connect Google or Microsoft calendar  
**So that** classify meetings and compare planned time

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
