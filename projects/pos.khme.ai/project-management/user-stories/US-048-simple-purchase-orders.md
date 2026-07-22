---
id: US-048
title: "Create a simple purchase order"
slug: "simple-purchase-orders"
personas: [P-004, P-002]
epic: "Forecasting & Resupply"
priority: "should-have"
complexity: "M"
tags: [forecasting, purchase-order, suppliers]
---

# US-048: Create a simple purchase order

## User Story

**As a** minimart owner (P-002),
**I want to** create a basic purchase order listing items and quantities to reorder from a supplier,
**So that** I have a clear record of what I ordered, can send it to the supplier, and can check deliveries against it when they arrive.

## Acceptance Criteria

- [ ] Given I have items flagged as low-stock or reorder-suggested ([[US-045]], [[US-046]]), when I choose "create PO," then those items and suggested quantities pre-fill, grouped by their linked supplier, and I can adjust quantities before finalizing.
- [ ] Given a PO is created, when I mark it "sent," then it becomes read-only for line items (to preserve an accurate record) and is available to share as a simple text/image summary (e.g. to paste into a Telegram message to the supplier) — no formal EDI integration required.
- [ ] Given a PO is open, when stock is received against it (register or companion app, [[US-040]]), then the PO's status updates automatically (partially received / fully received) and shows a variance between ordered and received for each line.
- [ ] Given a multi-store operator (P-004) manages several stores from one supplier, when creating a PO, then they can combine reorder needs from multiple stores into a single supplier order, then split the receiving by store afterward.

## Notes

Deliberately simple — no approval workflows, no formal document generation in v1. Depends on [[US-047]] for supplier linking. Related: [[US-031]], [[US-040]], [[US-045]].
