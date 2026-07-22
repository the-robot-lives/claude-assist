---
id: US-005
title: "Grant capture permissions"
slug: grant-capture-permissions
personas: [P-001, P-005, P-007]
epic: "Onboarding & Auth"
priority: must-have
complexity: medium
tags: [onboarding, setup]
---

# US-005: Grant capture permissions

## User Story

**As a** new user  
**I want to** grant screenshot and activity permissions with guidance  
**So that** avoid broken capture setup

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
