---
id: US-047
title: "Detect session resumption"
slug: detect-session-resumption
personas: [P-001, P-007]
epic: "Idle & Resumption Intelligence"
priority: must-have
complexity: medium
tags: [idle, resumption]
---

# US-047: Detect session resumption

## User Story

**As a** interrupted user  
**I want to** identify return after pause, sleep, or lock  
**So that** suggest the right next step

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
