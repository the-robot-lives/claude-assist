---
id: US-065
title: "Exclude private evidence"
slug: exclude-private-evidence
personas: [P-005, P-008]
epic: "Reporting & Billing"
priority: must-have
complexity: medium
tags: [reporting, billing]
---

# US-065: Exclude private evidence

## User Story

**As a** billing user  
**I want to** exclude redacted, deleted, or private screenshots from reports  
**So that** respect privacy controls

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
