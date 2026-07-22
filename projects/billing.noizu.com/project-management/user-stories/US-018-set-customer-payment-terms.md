---
id: US-018
title: "Set customer payment terms"
slug: set-customer-payment-terms
personas: [P-001, P-002]
epic: "Customers and Contacts"
priority: must-have
complexity: medium
tags: [customers, contacts]
---

# US-018: Set customer payment terms

## User Story

**As a** billing operator  
**I want to** define customer-specific due dates and terms  
**So that** maintain accurate account records

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the set customer payment terms flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
