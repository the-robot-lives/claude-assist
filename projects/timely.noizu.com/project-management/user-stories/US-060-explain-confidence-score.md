---
id: US-060
title: "Explain confidence score"
slug: explain-confidence-score
personas: [P-001, P-008]
epic: "Timeline Review & Analytics"
priority: should-have
complexity: medium
tags: [review, analytics]
---

# US-060: Explain confidence score

## User Story

**As a** reviewing user  
**I want to** show why an interval is high or low confidence  
**So that** trust automated classification

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
