---
id: US-042
title: "Prompt after idle return"
slug: prompt-after-idle-return
personas: [P-001, P-007]
epic: "Idle & Resumption Intelligence"
priority: must-have
complexity: medium
tags: [idle, resumption]
---

# US-042: Prompt after idle return

## User Story

**As a** interrupted user  
**I want to** ask what happened when I return from idle  
**So that** classify gaps while memory is fresh

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
