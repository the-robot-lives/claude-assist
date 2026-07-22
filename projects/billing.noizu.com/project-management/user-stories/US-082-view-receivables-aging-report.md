---
id: US-082
title: "View receivables aging report"
slug: view-receivables-aging-report
personas: [P-001, P-002, P-005]
epic: "Reporting and Exports"
priority: must-have
complexity: medium
tags: [reporting, exports]
---

# US-082: View receivables aging report

## User Story

**As a** finance operator  
**I want to** group unpaid invoices by age bucket  
**So that** understand revenue and support bookkeeping

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the view receivables aging report flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
