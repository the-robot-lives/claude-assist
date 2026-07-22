---
id: US-014
title: "Add customer contact"
slug: add-customer-contact
personas: [P-001, P-002]
epic: "Customers and Contacts"
priority: must-have
complexity: medium
tags: [customers, contacts]
---

# US-014: Add customer contact

## User Story

**As a** billing operator  
**I want to** add billing, technical, and executive contacts  
**So that** maintain accurate account records

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the add customer contact flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
