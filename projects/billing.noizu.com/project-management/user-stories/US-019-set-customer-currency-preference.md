---
id: US-019
title: "Set customer currency preference"
slug: set-customer-currency-preference
personas: [P-001, P-002]
epic: "Customers and Contacts"
priority: should-have
complexity: medium
tags: [customers, contacts]
---

# US-019: Set customer currency preference

## User Story

**As a** billing operator  
**I want to** assign default currency per customer  
**So that** maintain accurate account records

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the set customer currency preference flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
