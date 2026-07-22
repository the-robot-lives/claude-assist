---
id: US-118
title: "Send invoice workflow"
slug: send-invoice-workflow
personas: [P-001, P-002, P-007]
epic: "Invoices and Delivery"
priority: must-have
complexity: high
tags: [invoices, email, payments, audit]
---

# US-118: Send invoice workflow

## User Story

**As a** billing admin  
**I want to** review recipient, message, PDF readiness, and payment links before sending  
**So that** external invoice delivery is deliberate, complete, and auditable

## Acceptance Criteria

- **Given** an invoice is ready to send  
  **When** I open the send workflow  
  **Then** I can review recipient email, subject, message, PDF status, and payment rail selection
- **Given** no payment method is connected  
  **When** I attempt to send with payment links  
  **Then** the workflow blocks or warns before external delivery
- **Given** I confirm send  
  **When** the request is accepted  
  **Then** the system writes an append-only billing event with actor, timestamp, destination, and delivery state

## Notes

Human approval remains required before an invoice email leaves the workspace.
