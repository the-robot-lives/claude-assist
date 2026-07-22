---
id: US-003
title: "Accept invitation"
slug: accept-invitation
personas: [P-005, P-007]
epic: "Onboarding & Auth"
priority: must-have
complexity: medium
tags: [onboarding, setup]
---

# US-003: Accept invitation

## User Story

**As a** new user  
**I want to** accept an invitation with clear consent language  
**So that** understand what is tracked before joining

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
