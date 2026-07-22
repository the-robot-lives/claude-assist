---
id: US-087
title: "Connect GitHub"
slug: connect-github
personas: [P-001, P-003]
epic: "Integrations & API"
priority: could-have
complexity: medium
tags: [integration, api]
---

# US-087: Connect GitHub

## User Story

**As a** integrated workflow user  
**I want to** connect commits, pull requests, and issues  
**So that** attach development evidence to intervals

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
