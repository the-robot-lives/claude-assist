---
id: US-052
title: "Add estimate line items"
slug: add-estimate-line-items
personas: [P-003]
epic: "Estimates and Proposals"
priority: should-have
complexity: medium
tags: [estimates, approvals]
---

# US-052: Add estimate line items

## User Story

**As a** project delivery lead  
**I want to** build estimate scope from service items  
**So that** preserve scope and reduce duplicate entry

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the add estimate line items flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
