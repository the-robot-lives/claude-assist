---
id: US-078
title: "Redaction preview"
slug: redaction-preview
personas: [P-005]
epic: "Privacy, Policy & Compliance"
priority: should-have
complexity: medium
tags: [privacy, compliance]
---

# US-078: Redaction preview

## User Story

**As a** privacy-conscious user or admin  
**I want to** preview how redaction rules affect screenshots  
**So that** avoid false confidence

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
