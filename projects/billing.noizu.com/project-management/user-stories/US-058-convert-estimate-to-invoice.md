---
id: US-058
title: "Convert estimate to invoice"
slug: convert-estimate-to-invoice
personas: [P-001, P-002, P-003]
epic: "Estimates and Proposals"
priority: should-have
complexity: high
tags: [estimates, approvals]
---

# US-058: Convert estimate to invoice

## User Story

**As a** project delivery lead  
**I want to** turn accepted estimates into invoices  
**So that** preserve scope and reduce duplicate entry

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the convert estimate to invoice flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
