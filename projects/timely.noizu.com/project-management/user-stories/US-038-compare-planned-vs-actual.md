---
id: US-038
title: "Compare planned vs actual"
slug: compare-planned-vs-actual
personas: [P-001, P-004, P-007]
epic: "Core Tracking & Evidence"
priority: should-have
complexity: medium
tags: [tracking, timeline]
---

# US-038: Compare planned vs actual

## User Story

**As a** daily user  
**I want to** compare tracked work with calendar blocks  
**So that** understand schedule drift

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
