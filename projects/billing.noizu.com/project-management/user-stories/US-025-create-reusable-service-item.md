---
id: US-025
title: "Create reusable service item"
slug: create-reusable-service-item
personas: [P-001, P-002]
epic: "Projects and Service Catalog"
priority: must-have
complexity: medium
tags: [projects, catalog]
---

# US-025: Create reusable service item

## User Story

**As a** delivery or billing operator  
**I want to** define reusable service line items with price defaults  
**So that** reuse consistent billing context

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the create reusable service item flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
