---
id: US-017
title: "Capture customer tax ID"
slug: capture-customer-tax-id
personas: [P-002, P-005]
epic: "Customers and Contacts"
priority: must-have
complexity: medium
tags: [customers, contacts]
---

# US-017: Capture customer tax ID

## User Story

**As a** billing operator  
**I want to** store tax identifiers for compliant invoices  
**So that** maintain accurate account records

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the capture customer tax id flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
