---
id: US-029
title: "Track project service period"
slug: track-project-service-period
personas: [P-003, P-004]
epic: "Projects and Service Catalog"
priority: must-have
complexity: medium
tags: [projects, catalog]
---

# US-029: Track project service period

## User Story

**As a** delivery or billing operator  
**I want to** store service periods used on invoice lines  
**So that** reuse consistent billing context

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the track project service period flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
