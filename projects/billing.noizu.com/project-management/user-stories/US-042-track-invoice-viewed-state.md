---
id: US-042
title: "Track invoice viewed state"
slug: track-invoice-viewed-state
personas: [P-002, P-006]
epic: "Invoices and Delivery"
priority: should-have
complexity: medium
tags: [invoices, delivery]
---

# US-042: Track invoice viewed state

## User Story

**As a** billing operator  
**I want to** record when a client views an invoice or payment link  
**So that** send accurate invoices and preserve state

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the track invoice viewed state flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
