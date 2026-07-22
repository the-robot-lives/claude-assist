---
id: US-047
title: "Search and filter invoices"
slug: search-and-filter-invoices
personas: [P-001, P-002, P-006]
epic: "Invoices and Delivery"
priority: must-have
complexity: medium
tags: [invoices, delivery]
---

# US-047: Search and filter invoices

## User Story

**As a** billing operator  
**I want to** find invoices by customer, status, amount, and due date  
**So that** send accurate invoices and preserve state

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the search and filter invoices flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
