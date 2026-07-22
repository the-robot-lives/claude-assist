---
id: US-088
title: "Export payments CSV"
slug: export-payments-csv
personas: [P-002, P-005]
epic: "Reporting and Exports"
priority: must-have
complexity: medium
tags: [reporting, exports]
---

# US-088: Export payments CSV

## User Story

**As a** finance operator  
**I want to** download payment records for reconciliation  
**So that** understand revenue and support bookkeeping

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the export payments csv flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
