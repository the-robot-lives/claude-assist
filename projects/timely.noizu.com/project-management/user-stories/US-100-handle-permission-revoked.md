---
id: US-100
title: "Handle permission revoked"
slug: handle-permission-revoked
personas: [P-001, P-005]
epic: "Accessibility, Reliability & Edge Cases"
priority: must-have
complexity: medium
tags: [accessibility, reliability]
---

# US-100: Handle permission revoked

## User Story

**As a** Timely user in an edge condition  
**I want to** detect revoked OS permissions and guide repair  
**So that** restore capture safely

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
