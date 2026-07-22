---
id: US-098
title: "Localize date and time formats"
slug: localize-date-and-time-formats
personas: [P-001, P-005]
epic: "Accessibility, Reliability & Edge Cases"
priority: should-have
complexity: medium
tags: [accessibility, reliability]
---

# US-098: Localize date and time formats

## User Story

**As a** Timely user in an edge condition  
**I want to** show dates, weeks, and currencies by locale  
**So that** support international clients

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
