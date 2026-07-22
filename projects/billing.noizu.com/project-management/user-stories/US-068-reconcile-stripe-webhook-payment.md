---
id: US-068
title: "Reconcile Stripe webhook payment"
slug: reconcile-stripe-webhook-payment
personas: [P-002, P-005]
epic: "Payments and Credits"
priority: should-have
complexity: high
tags: [payments, credits, stripe]
---

# US-068: Reconcile Stripe webhook payment

## User Story

**As a** finance operator  
**I want to** match imported Stripe payment events to invoices  
**So that** keep balances correct and collectible

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the reconcile stripe webhook payment flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
