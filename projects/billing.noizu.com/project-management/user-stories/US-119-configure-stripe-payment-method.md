---
id: US-119
title: "Configure Stripe payment method"
slug: configure-stripe-payment-method
personas: [P-001, P-002]
epic: "Payments and Credits"
priority: must-have
complexity: high
tags: [payments, stripe, settings, audit]
---

# US-119: Configure Stripe payment method

## User Story

**As a** workspace owner  
**I want to** connect Stripe hosted payment links and webhooks  
**So that** customers can pay invoices by card without Billing Noizu storing card data

## Acceptance Criteria

- **Given** I have payment settings permission  
  **When** I configure Stripe  
  **Then** the workspace stores provider status, public label, webhook endpoint, and non-sensitive provider references
- **Given** Stripe webhook verification fails  
  **When** I save settings  
  **Then** the method remains in needs-review or not-connected state
- **Given** Stripe is ready  
  **When** an invoice is sent  
  **Then** the invoice can include a hosted Stripe payment link

## Notes

Billing Noizu must not store raw card data.
