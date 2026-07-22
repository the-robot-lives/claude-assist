---
id: US-037
title: "Bulk edit intervals"
slug: bulk-edit-intervals
personas: [P-001, P-004]
epic: "Core Tracking & Evidence"
priority: should-have
complexity: medium
tags: [tracking, timeline]
---

# US-037: Bulk edit intervals

## User Story

**As a** daily user  
**I want to** apply project or billable changes to many intervals  
**So that** clean up a day efficiently

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
