---
id: US-121
title: "Configure ACH payment method"
slug: configure-ach-payment-method
personas: [P-001, P-002, P-005]
epic: "Payments and Credits"
priority: must-have
complexity: high
tags: [payments, ach, settings, audit]
---

# US-121: Configure ACH payment method

## User Story

**As a** finance operator  
**I want to** configure ACH payment instructions and settlement rules  
**So that** bank-transfer payments can be recorded without prematurely marking invoices paid

## Acceptance Criteria

- **Given** ACH is configured  
  **When** invoice payment instructions are rendered  
  **Then** only approved public instructions appear to the customer
- **Given** an ACH payment is entered before settlement  
  **When** the payment is recorded  
  **Then** the invoice shows pending or partially settled state until confirmation
- **Given** ACH instructions change  
  **When** settings are saved  
  **Then** the change is audit logged and does not rewrite historical invoices

## Notes

ACH workflows must distinguish received notice from settled funds.
