---
id: US-004
title: "Install desktop agent"
slug: install-desktop-agent
personas: [P-001, P-004, P-007]
epic: "Onboarding & Auth"
priority: must-have
complexity: medium
tags: [onboarding, setup]
---

# US-004: Install desktop agent

## User Story

**As a** new user  
**I want to** install the desktop capture agent  
**So that** capture activity reliably

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
