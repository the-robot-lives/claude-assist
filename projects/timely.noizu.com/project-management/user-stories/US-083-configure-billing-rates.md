---
id: US-083
title: "Configure billing rates"
slug: configure-billing-rates
personas: [P-001, P-006]
epic: "Workspace Administration"
priority: should-have
complexity: medium
tags: [admin, workspace]
---

# US-083: Configure billing rates

## User Story

**As a** workspace admin  
**I want to** set rates by client, project, task, or person  
**So that** calculate totals correctly

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
