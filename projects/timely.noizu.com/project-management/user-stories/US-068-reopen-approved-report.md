---
id: US-068
title: "Reopen approved report"
slug: reopen-approved-report
personas: [P-002, P-006, P-008]
epic: "Reporting & Billing"
priority: could-have
complexity: medium
tags: [reporting, billing]
---

# US-068: Reopen approved report

## User Story

**As a** billing user  
**I want to** reopen an approved report with reason  
**So that** handle corrections after review

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
