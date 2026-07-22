---
id: US-054
title: "Filter timeline by evidence"
slug: filter-timeline-by-evidence
personas: [P-001, P-006]
epic: "Timeline Review & Analytics"
priority: should-have
complexity: medium
tags: [review, analytics]
---

# US-054: Filter timeline by evidence

## User Story

**As a** reviewing user  
**I want to** show intervals with screenshots, metadata, manual time, or low confidence  
**So that** find records needing review

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
