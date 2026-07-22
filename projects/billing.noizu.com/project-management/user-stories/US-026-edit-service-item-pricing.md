---
id: US-026
title: "Edit service item pricing"
slug: edit-service-item-pricing
personas: [P-002]
epic: "Projects and Service Catalog"
priority: should-have
complexity: medium
tags: [projects, catalog]
---

# US-026: Edit service item pricing

## User Story

**As a** delivery or billing operator  
**I want to** update service prices while preserving invoice history  
**So that** reuse consistent billing context

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the edit service item pricing flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
