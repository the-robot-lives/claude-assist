---
id: US-085
title: "View tax summary"
slug: view-tax-summary
personas: [P-002, P-005]
epic: "Reporting and Exports"
priority: should-have
complexity: medium
tags: [reporting, exports]
---

# US-085: View tax summary

## User Story

**As a** finance operator  
**I want to** summarize taxable amount and taxes collected  
**So that** understand revenue and support bookkeeping

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the view tax summary flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
