---
id: US-006
title: "Run capture test"
slug: run-capture-test
personas: [P-001, P-005]
epic: "Onboarding & Auth"
priority: must-have
complexity: medium
tags: [onboarding, setup]
---

# US-006: Run capture test

## User Story

**As a** new user  
**I want to** run a test screenshot and metadata check  
**So that** confirm capture works before live tracking

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
