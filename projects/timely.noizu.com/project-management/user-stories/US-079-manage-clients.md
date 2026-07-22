---
id: US-079
title: "Manage clients"
slug: manage-clients
personas: [P-001, P-002]
epic: "Workspace Administration"
priority: must-have
complexity: medium
tags: [admin, workspace]
---

# US-079: Manage clients

## User Story

**As a** workspace admin  
**I want to** create, edit, archive, and merge clients  
**So that** keep time organized

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
