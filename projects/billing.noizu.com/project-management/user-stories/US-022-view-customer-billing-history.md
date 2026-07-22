---
id: US-022
title: "View customer billing history"
slug: view-customer-billing-history
personas: [P-001, P-002, P-006]
epic: "Customers and Contacts"
priority: must-have
complexity: medium
tags: [customers, contacts]
---

# US-022: View customer billing history

## User Story

**As a** billing operator  
**I want to** see invoices, payments, credits, and reminders for one customer  
**So that** maintain accurate account records

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the view customer billing history flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
