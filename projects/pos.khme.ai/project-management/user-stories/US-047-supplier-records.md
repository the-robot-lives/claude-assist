---
id: US-047
title: "Maintain supplier records"
slug: "supplier-records"
personas: [P-004, P-002]
epic: "Forecasting & Resupply"
priority: "should-have"
complexity: "S"
tags: [forecasting, suppliers, purchasing]
---

# US-047: Maintain supplier records

## User Story

**As a** multi-store operator (P-004),
**I want to** keep a simple record of each supplier — name, contact info, phone/Telegram, items they typically supply, and payment terms,
**So that** reordering is fast and consistent, and I'm not hunting through a phone contacts app or a notebook to remember who sells what.

## Acceptance Criteria

- [ ] Given I add a new supplier, when I enter name, phone/contact, and optionally the items they supply, then the supplier is saved and available for linking on purchase orders ([[US-048]]).
- [ ] Given an item has one or more linked suppliers, when I view the item, then I can see who supplies it and jump straight to creating a PO for that supplier.
- [ ] Given a supplier record exists, when I view its detail page, then I see a simple history of past deliveries/POs with that supplier (dates, totals), without needing a separate reporting tool.
- [ ] Given a minimart owner (P-002) with informal cash suppliers (a guy who drops off produce), when adding a supplier, then all fields beyond name are optional — the record can be as lightweight as "Uncle Vin, 012-xxx-xxx."

## Notes

Intentionally lightweight — not a full vendor-management system. Related: [[US-031]], [[US-040]], [[US-048]].
