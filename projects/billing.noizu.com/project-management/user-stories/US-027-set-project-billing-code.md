---
id: US-027
title: "Set project billing code"
slug: set-project-billing-code
personas: [P-003, P-005]
epic: "Projects and Service Catalog"
priority: should-have
complexity: medium
tags: [projects, catalog]
---

# US-027: Set project billing code

## User Story

**As a** delivery or billing operator  
**I want to** assign internal billing codes for exports  
**So that** reuse consistent billing context

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the set project billing code flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
