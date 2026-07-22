---
id: US-049
title: "Download invoice PDF"
slug: download-invoice-pdf
personas: [P-002, P-004, P-005]
epic: "Invoices and Delivery"
priority: must-have
complexity: low
tags: [invoices, delivery]
---

# US-049: Download invoice PDF

## User Story

**As a** billing operator  
**I want to** download current or historical invoice PDFs  
**So that** send accurate invoices and preserve state

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the download invoice pdf flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
