---
id: US-089
title: "Connect Slack"
slug: connect-slack
personas: [P-003]
epic: "Integrations & API"
priority: could-have
complexity: medium
tags: [integration, api]
---

# US-089: Connect Slack

## User Story

**As a** integrated workflow user  
**I want to** connect status and incident channels  
**So that** identify support interruptions

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
