---
id: US-045
title: "Duplicate invoice as draft"
slug: duplicate-invoice-as-draft
personas: [P-001, P-002]
epic: "Invoices and Delivery"
priority: should-have
complexity: low
tags: [invoices, delivery]
---

# US-045: Duplicate invoice as draft

## User Story

**As a** billing operator  
**I want to** copy a previous invoice for similar work  
**So that** send accurate invoices and preserve state

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the duplicate invoice as draft flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
