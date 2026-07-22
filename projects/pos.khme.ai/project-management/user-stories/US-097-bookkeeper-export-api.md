---
id: US-097
title: "Bookkeeper/accounting export API or webhook"
slug: "bookkeeper-export-api"
personas: [P-006]
epic: "Integrations & API"
priority: "could-have"
complexity: "M"
tags: [integration, api, export, accounting]
---

# US-097: Bookkeeper/accounting export API or webhook

## User Story

**As a** bookkeeper (P-006),
**I want** an API or webhook that delivers transaction and reconciliation data to my accounting workflow,
**So that** I don't have to manually re-enter sales data every month.

## Acceptance Criteria

- [ ] Given a store owner enables the accounting export integration, when they generate an API key or configure a webhook URL, then completed sales and cash-up records begin flowing to that endpoint on a configurable schedule (real-time webhook or daily batch).
- [ ] Given the export contains financial data, when it's generated, then it includes both KHR and USD amounts per the store's exchange-rate convention (US-085), not a single blended currency.
- [ ] Given an export delivery fails (webhook endpoint unreachable), when retries are exhausted, then the failure is logged and surfaced to the store owner so no data is silently lost.

## Notes

Could-have for v1 — bookkeepers (P-006) can use manual data export (US-098) as an interim path. Depends on US-085.
