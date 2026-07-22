---
id: US-083
title: "View revenue by customer"
slug: view-revenue-by-customer
personas: [P-001, P-002]
epic: "Reporting and Exports"
priority: should-have
complexity: medium
tags: [reporting, exports]
---

# US-083: View revenue by customer

## User Story

**As a** finance operator  
**I want to** compare paid and outstanding revenue by customer  
**So that** understand revenue and support bookkeeping

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the view revenue by customer flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
