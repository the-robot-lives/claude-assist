---
id: US-606
title: "Exclusion Cascade Stops at Fourth Degree"
slug: exclusion-cascade-stops-at-fourth-degree
personas: [P-001]
epic: "Safety: Blocking & Exclusions"
priority: could-have
complexity: medium
tags: [safety, exclusions, cascade]
---

# US-606: Exclusion Cascade Stops at Fourth Degree

## User Story

**As a** bridge-builder
**I want to** know that interest exclusion cascades stop at the fourth degree of connection
**So that** the propagation has a well-defined boundary and does not affect the broader public

## Acceptance Criteria

- **Given** I have excluded interest #X and the cascade is active through degree 3
  **When** a fifth-degree connection publishes a post tagged #X
  **Then** that post is not suppressed and may reach public audiences normally

- **Given** the system displays my exclusion settings
  **When** I view an active exclusion
  **Then** the UI shows the cascade depth applied (e.g., "applies through 4th degree")

## Notes
Platform maximum cascade depth is 4 to match the social graph model.
