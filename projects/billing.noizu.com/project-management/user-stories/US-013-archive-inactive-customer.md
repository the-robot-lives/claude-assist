---
id: US-013
title: "Archive inactive customer"
slug: archive-inactive-customer
personas: [P-001, P-002]
epic: "Customers and Contacts"
priority: should-have
complexity: low
tags: [customers, contacts]
---

# US-013: Archive inactive customer

## User Story

**As a** billing operator  
**I want to** archive inactive customers while preserving history  
**So that** maintain accurate account records

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the archive inactive customer flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
