---
id: US-098
title: "Data export/portability (full store data takeout)"
slug: "data-export-portability"
personas: [P-004, P-006, P-007]
epic: "Integrations & API"
priority: "could-have"
complexity: "M"
tags: [integration, export, portability]
---

# US-098: Data export/portability (full store data takeout)

## User Story

**As a** multi-store operator (P-004),
**I want to** export a complete copy of my store's data (catalog, transactions, inventory history),
**So that** I retain ownership of my data and can migrate or archive it independent of the app.

## Acceptance Criteria

- [ ] Given Settings > Data Export, when the user requests a full export, then a downloadable archive (e.g., CSV/JSON bundle) containing catalog, transaction history, and inventory adjustments is generated and available within a reasonable time for the data volume.
- [ ] Given the export is generated, when the user downloads it, then all monetary values are labeled with both currency and the exchange rate in effect at the time of each transaction.
- [ ] Given a store has a large transaction history, when an export is requested, then generation happens asynchronously with a notification when ready, rather than blocking the UI.

## Notes

Could-have — supports the trust/data-ownership principle but not required for launch. Related: US-097 (recurring export vs. this one-time takeout).
