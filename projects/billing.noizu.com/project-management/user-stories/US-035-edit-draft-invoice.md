---
id: US-035
title: "Edit draft invoice"
slug: edit-draft-invoice
personas: [P-001, P-002]
epic: "Invoices and Delivery"
priority: must-have
complexity: medium
tags: [invoices, delivery]
---

# US-035: Edit draft invoice

## User Story

**As a** billing operator  
**I want to** edit line items and terms before sending  
**So that** send accurate invoices and preserve state

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the edit draft invoice flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
