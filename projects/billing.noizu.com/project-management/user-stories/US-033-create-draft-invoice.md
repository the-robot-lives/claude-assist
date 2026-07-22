---
id: US-033
title: "Create draft invoice"
slug: create-draft-invoice
personas: [P-001, P-002]
epic: "Invoices and Delivery"
priority: must-have
complexity: medium
tags: [invoices, delivery]
---

# US-033: Create draft invoice

## User Story

**As a** billing operator  
**I want to** create a draft invoice for a customer  
**So that** send accurate invoices and preserve state

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the create draft invoice flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
