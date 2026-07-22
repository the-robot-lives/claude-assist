---
id: US-020
title: "Add internal customer notes"
slug: add-internal-customer-notes
personas: [P-002, P-006]
epic: "Customers and Contacts"
priority: should-have
complexity: low
tags: [customers, contacts]
---

# US-020: Add internal customer notes

## User Story

**As a** billing operator  
**I want to** record account notes hidden from clients  
**So that** maintain accurate account records

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the add internal customer notes flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
