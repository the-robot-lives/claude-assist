---
id: US-001
title: "Create workspace"
slug: create-workspace
personas: [P-001, P-002, P-004]
epic: "Onboarding & Auth"
priority: must-have
complexity: medium
tags: [onboarding, setup]
---

# US-001: Create workspace

## User Story

**As a** new user  
**I want to** create a workspace with default billing and privacy settings  
**So that** start tracking without setup ambiguity

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
