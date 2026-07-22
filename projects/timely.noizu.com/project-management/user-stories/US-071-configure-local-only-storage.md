---
id: US-071
title: "Configure local-only storage"
slug: configure-local-only-storage
personas: [P-005, P-008]
epic: "Privacy, Policy & Compliance"
priority: should-have
complexity: medium
tags: [privacy, compliance]
---

# US-071: Configure local-only storage

## User Story

**As a** privacy-conscious user or admin  
**I want to** keep screenshots on device while syncing metadata  
**So that** reduce privacy risk

## Acceptance Criteria

- **Given** I have access to the relevant Timely workspace state  
  **When** I complete this action  
  **Then** Timely updates the timeline, evidence, permissions, or report state consistently

- **Given** the action affects billing, privacy, or audit history  
  **When** the result is saved  
  **Then** Timely records the source, actor, timestamp, and confidence where applicable

## Notes
Keep the interaction explicit about confidence, privacy, and whether the result affects billing or audit history.
