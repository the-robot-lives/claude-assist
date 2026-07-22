---
id: US-067
title: "Set approval workflow"
slug: set-approval-workflow
personas: [P-002, P-006]
epic: "Reporting & Billing"
priority: should-have
complexity: medium
tags: [reporting, billing]
---

# US-067: Set approval workflow

## User Story

**As a** billing user  
**I want to** require manager approval before export  
**So that** prevent premature billing

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
