---
id: US-030
title: "Attach delivery notes to project"
slug: attach-delivery-notes-to-project
personas: [P-003, P-006]
epic: "Projects and Service Catalog"
priority: should-have
complexity: medium
tags: [projects, catalog]
---

# US-030: Attach delivery notes to project

## User Story

**As a** delivery or billing operator  
**I want to** capture client-visible delivery notes for billing  
**So that** reuse consistent billing context

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the attach delivery notes to project flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
