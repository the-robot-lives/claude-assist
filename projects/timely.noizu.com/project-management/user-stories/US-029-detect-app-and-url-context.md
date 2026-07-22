---
id: US-029
title: "Detect app and URL context"
slug: detect-app-and-url-context
personas: [P-001, P-004, P-007]
epic: "Core Tracking & Evidence"
priority: must-have
complexity: medium
tags: [tracking, timeline]
---

# US-029: Detect app and URL context

## User Story

**As a** daily user  
**I want to** record active app, title, and URL where allowed  
**So that** classify work with less manual effort

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
