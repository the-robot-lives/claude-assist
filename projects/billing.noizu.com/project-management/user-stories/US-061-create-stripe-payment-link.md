---
id: US-061
title: "Create Stripe payment link"
slug: create-stripe-payment-link
personas: [P-001, P-002, P-004]
epic: "Payments and Credits"
priority: must-have
complexity: high
tags: [payments, credits, stripe]
---

# US-061: Create Stripe payment link

## User Story

**As a** finance operator  
**I want to** generate a hosted payment link for an invoice  
**So that** keep balances correct and collectible

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the create stripe payment link flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
