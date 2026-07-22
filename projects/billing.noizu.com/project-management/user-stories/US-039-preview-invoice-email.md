---
id: US-039
title: "Preview invoice email"
slug: preview-invoice-email
personas: [P-001, P-002, P-006]
epic: "Invoices and Delivery"
priority: must-have
complexity: medium
tags: [invoices, delivery]
---

# US-039: Preview invoice email

## User Story

**As a** billing operator  
**I want to** review recipient, subject, body, and attachments  
**So that** send accurate invoices and preserve state

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the preview invoice email flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
