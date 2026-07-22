---
id: US-122
title: "Record provider payment"
slug: record-provider-payment
personas: [P-002, P-005]
epic: "Payments and Credits"
priority: must-have
complexity: medium
tags: [payments, stripe, paypal, ach, audit]
---

# US-122: Record provider payment

## User Story

**As a** finance operator  
**I want to** record Stripe, PayPal, ACH, or manual payments with references  
**So that** invoice balances stay correct even when payment events arrive outside automation

## Acceptance Criteria

- **Given** an invoice has an open balance  
  **When** I record a provider payment  
  **Then** the payment captures provider, amount, received date, processor reference, and note
- **Given** the amount is less than the balance  
  **When** the payment is saved  
  **Then** the invoice remains partially paid and the remaining balance is visible
- **Given** the payment rail requires settlement confirmation  
  **When** I record the payment  
  **Then** the event does not mark the invoice paid until settlement rules allow it

## Notes

Payment corrections should be modeled as new events rather than destructive edits.
