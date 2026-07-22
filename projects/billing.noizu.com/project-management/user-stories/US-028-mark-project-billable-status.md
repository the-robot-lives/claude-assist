---
id: US-028
title: "Mark project billable status"
slug: mark-project-billable-status
personas: [P-003, P-002]
epic: "Projects and Service Catalog"
priority: should-have
complexity: low
tags: [projects, catalog]
---

# US-028: Mark project billable status

## User Story

**As a** delivery or billing operator  
**I want to** mark projects as billable, non-billable, or paused  
**So that** reuse consistent billing context

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the mark project billable status flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
