---
id: US-012
title: "Edit customer profile"
slug: edit-customer-profile
personas: [P-001, P-002]
epic: "Customers and Contacts"
priority: must-have
complexity: medium
tags: [customers, contacts]
---

# US-012: Edit customer profile

## User Story

**As a** billing operator  
**I want to** update customer details without breaking historical invoices  
**So that** maintain accurate account records

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the edit customer profile flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
