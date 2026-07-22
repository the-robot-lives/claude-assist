---
id: US-016
title: "Store billing and shipping addresses"
slug: store-billing-and-shipping-addresses
personas: [P-001, P-002, P-004]
epic: "Customers and Contacts"
priority: must-have
complexity: medium
tags: [customers, contacts]
---

# US-016: Store billing and shipping addresses

## User Story

**As a** billing operator  
**I want to** store multiple address types for invoice rendering  
**So that** maintain accurate account records

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the store billing and shipping addresses flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
