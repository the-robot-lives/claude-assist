---
id: US-084
title: "View revenue by project"
slug: view-revenue-by-project
personas: [P-001, P-003]
epic: "Reporting and Exports"
priority: should-have
complexity: medium
tags: [reporting, exports]
---

# US-084: View revenue by project

## User Story

**As a** finance operator  
**I want to** compare revenue by project and service period  
**So that** understand revenue and support bookkeeping

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the view revenue by project flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
