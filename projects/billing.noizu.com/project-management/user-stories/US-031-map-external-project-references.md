---
id: US-031
title: "Map external project references"
slug: map-external-project-references
personas: [P-003, P-001]
epic: "Projects and Service Catalog"
priority: could-have
complexity: medium
tags: [projects, catalog]
---

# US-031: Map external project references

## User Story

**As a** delivery or billing operator  
**I want to** store IDs from timely, support, or consulting systems  
**So that** reuse consistent billing context

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the map external project references flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
