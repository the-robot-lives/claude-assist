---
id: US-023
title: "Create billable project"
slug: create-billable-project
personas: [P-001, P-003]
epic: "Projects and Service Catalog"
priority: must-have
complexity: medium
tags: [projects, catalog]
---

# US-023: Create billable project

## User Story

**As a** delivery or billing operator  
**I want to** create a project tied to a customer  
**So that** reuse consistent billing context

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the create billable project flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
