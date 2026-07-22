---
id: US-094
title: "Reconcile imported payment events"
slug: reconcile-imported-payment-events
personas: [P-002, P-005]
epic: "Agent-Assisted Billing"
priority: could-have
complexity: high
tags: [agent-assisted, automation]
---

# US-094: Reconcile imported payment events

## User Story

**As a** billing operator  
**I want to** suggest matches between imported events and open invoices  
**So that** save time while keeping human approval on financial actions

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the reconcile imported payment events flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
