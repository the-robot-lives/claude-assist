---
id: US-081
title: "View accounts receivable dashboard"
slug: view-accounts-receivable-dashboard
personas: [P-001, P-002]
epic: "Reporting and Exports"
priority: must-have
complexity: high
tags: [reporting, exports]
---

# US-081: View accounts receivable dashboard

## User Story

**As a** finance operator  
**I want to** monitor outstanding, overdue, paid, and risk totals  
**So that** understand revenue and support bookkeeping

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the view accounts receivable dashboard flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
