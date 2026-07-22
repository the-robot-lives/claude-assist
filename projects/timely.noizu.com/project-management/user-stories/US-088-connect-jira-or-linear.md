---
id: US-088
title: "Connect Jira or Linear"
slug: connect-jira-or-linear
personas: [P-001, P-003]
epic: "Integrations & API"
priority: could-have
complexity: medium
tags: [integration, api]
---

# US-088: Connect Jira or Linear

## User Story

**As a** integrated workflow user  
**I want to** connect issue tracker tasks  
**So that** reduce duplicate task entry

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
