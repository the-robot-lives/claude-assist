---
id: US-086
title: "Export customers CSV"
slug: export-customers-csv
personas: [P-002, P-005]
epic: "Reporting and Exports"
priority: must-have
complexity: low
tags: [reporting, exports]
---

# US-086: Export customers CSV

## User Story

**As a** finance operator  
**I want to** download customer data for external tools  
**So that** understand revenue and support bookkeeping

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the export customers csv flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
