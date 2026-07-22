---
id: US-026
title: "Delete screenshot"
slug: delete-screenshot
personas: [P-001, P-005, P-008]
epic: "Core Tracking & Evidence"
priority: must-have
complexity: medium
tags: [tracking, timeline]
---

# US-026: Delete screenshot

## User Story

**As a** daily user  
**I want to** delete a sensitive screenshot with audit visibility  
**So that** protect confidential material

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
