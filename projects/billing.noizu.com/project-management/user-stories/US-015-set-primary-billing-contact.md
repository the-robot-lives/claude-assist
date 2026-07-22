---
id: US-015
title: "Set primary billing contact"
slug: set-primary-billing-contact
personas: [P-001, P-002]
epic: "Customers and Contacts"
priority: must-have
complexity: low
tags: [customers, contacts]
---

# US-015: Set primary billing contact

## User Story

**As a** billing operator  
**I want to** mark who receives invoice emails  
**So that** maintain accurate account records

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the set primary billing contact flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
