---
id: US-048
title: "Show invoice activity timeline"
slug: show-invoice-activity-timeline
personas: [P-002, P-005, P-006]
epic: "Invoices and Delivery"
priority: must-have
complexity: medium
tags: [invoices, delivery]
---

# US-048: Show invoice activity timeline

## User Story

**As a** billing operator  
**I want to** display create, edit, send, view, payment, and reminder events  
**So that** send accurate invoices and preserve state

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the show invoice activity timeline flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
