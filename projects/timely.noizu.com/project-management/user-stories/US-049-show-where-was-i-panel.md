---
id: US-049
title: "Show where-was-I panel"
slug: show-where-was-i-panel
personas: [P-004, P-007]
epic: "Idle & Resumption Intelligence"
priority: should-have
complexity: medium
tags: [idle, resumption]
---

# US-049: Show where-was-I panel

## User Story

**As a** interrupted user  
**I want to** show recent screenshots, notes, and files after resumption  
**So that** rebuild context quickly

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
