---
id: US-077
title: "Set role permissions"
slug: set-role-permissions
personas: [P-002, P-008]
epic: "Privacy, Policy & Compliance"
priority: must-have
complexity: medium
tags: [privacy, compliance]
---

# US-077: Set role permissions

## User Story

**As a** privacy-conscious user or admin  
**I want to** control who can see screenshots, summaries, and exports  
**So that** enforce least privilege

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
