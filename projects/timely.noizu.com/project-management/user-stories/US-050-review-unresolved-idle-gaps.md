---
id: US-050
title: "Review unresolved idle gaps"
slug: review-unresolved-idle-gaps
personas: [P-001, P-006]
epic: "Idle & Resumption Intelligence"
priority: must-have
complexity: medium
tags: [idle, resumption]
---

# US-050: Review unresolved idle gaps

## User Story

**As a** interrupted user  
**I want to** see a queue of unclassified idle gaps  
**So that** clean the timeline before reporting

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
