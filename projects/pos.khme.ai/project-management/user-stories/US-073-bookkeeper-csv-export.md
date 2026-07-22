---
id: US-073
title: "Bookkeeper CSV Export"
slug: "bookkeeper-csv-export"
personas: [P-006]
epic: "Reporting & Insights"
priority: "must-have"
complexity: "M"
tags: [reporting, export, bookkeeping]
---

# US-073: Bookkeeper CSV Export

## User Story

**As a** bookkeeper (P-006),
**I want to** export sales, cash reconciliation, and payout data as CSV for a chosen date range,
**So that** I can bring it into my own spreadsheet or accounting software instead of manually re-entering numbers from the app.

## Acceptance Criteria

- [ ] Given the bookkeeper selects a date range and data type (sales transactions, shift cash-ups, payouts/drops), when they tap "Export CSV," then a file is generated with clearly labeled columns including currency (KHR/USD) for every monetary field.
- [ ] Given the export is generated, when it completes, then the bookkeeper can download it directly or have it sent to a configured email/cloud destination.
- [ ] Given a multi-store operator's bookkeeper exports data, when they have access to more than one store, then the export includes a store identifier column and can be filtered to one or all assigned stores.
- [ ] Given the export contains monetary totals, when opened in a spreadsheet, then KHR and USD columns are numeric (not pre-formatted strings) so they can be summed and recalculated without cleanup.

## Notes

Depends on [[US-053]] (cash-up data), [[US-054]]/[[US-055]] (drops/payouts), and Register/Checkout epic transaction data (US-001–025). Bookkeeper's core workflow — the export must be clean enough to use with zero manual reformatting.
