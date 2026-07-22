---
id: US-076
title: "Review audit log"
slug: review-audit-log
personas: [P-008]
epic: "Privacy, Policy & Compliance"
priority: must-have
complexity: medium
tags: [privacy, compliance]
---

# US-076: Review audit log

## User Story

**As a** privacy-conscious user or admin  
**I want to** see policy, interval, evidence, and export changes  
**So that** support compliance review

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
