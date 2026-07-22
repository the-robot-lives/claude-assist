---
id: US-021
title: "Tag and filter customers"
slug: tag-and-filter-customers
personas: [P-001, P-002, P-006]
epic: "Customers and Contacts"
priority: should-have
complexity: medium
tags: [customers, contacts]
---

# US-021: Tag and filter customers

## User Story

**As a** billing operator  
**I want to** organize customers by status, risk, and service type  
**So that** maintain accurate account records

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the tag and filter customers flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
