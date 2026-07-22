---
id: US-120
title: "Configure PayPal payment method"
slug: configure-paypal-payment-method
personas: [P-001, P-002]
epic: "Payments and Credits"
priority: should-have
complexity: high
tags: [payments, paypal, settings, audit]
---

# US-120: Configure PayPal payment method

## User Story

**As a** workspace owner  
**I want to** connect PayPal checkout and webhook reconciliation  
**So that** customers who prefer PayPal can pay invoices through an approved rail

## Acceptance Criteria

- **Given** I configure PayPal credentials  
  **When** the provider check succeeds  
  **Then** PayPal becomes available as a send-time payment option
- **Given** PayPal sends a transaction update  
  **When** the webhook is verified  
  **Then** the event can reconcile to an invoice or enter unmatched review
- **Given** PayPal is not connected  
  **When** I send an invoice  
  **Then** PayPal cannot be presented as a live payment option

## Notes

PayPal records should preserve processor references for customer support and reconciliation.
