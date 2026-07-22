---
id: US-117
title: "View invoice detail workspace"
slug: view-invoice-detail-workspace
personas: [P-001, P-002, P-005]
epic: "Invoices and Delivery"
priority: must-have
complexity: medium
tags: [invoices, payments, audit]
---

# US-117: View invoice detail workspace

## User Story

**As a** finance operator  
**I want to** open a single invoice with line items, delivery state, payment methods, and activity  
**So that** I can decide whether to send, collect, adjust, or reconcile it

## Acceptance Criteria

- **Given** an invoice exists  
  **When** I open its detail route  
  **Then** I can see invoice identity, customer context, totals, balance, due date, available payment rails, and activity history
- **Given** the invoice does not exist or is not yet loaded  
  **When** I open the route  
  **Then** the interface shows a clear empty/error state without fake financial data
- **Given** I have permission  
  **When** I review the invoice  
  **Then** send and record-payment actions are available from the same workspace

## Notes

The detail route is the canonical context for invoice send, payment recording, payment history, and audit events.
