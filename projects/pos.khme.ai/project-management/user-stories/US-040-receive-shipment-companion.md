---
id: US-040
title: "Receive a shipment against expected quantities"
slug: "receive-shipment-companion"
personas: [P-005]
epic: "Companion App"
priority: "must-have"
complexity: "M"
tags: [companion-app, receiving, purchase-order]
---

# US-040: Receive a shipment against expected quantities

## User Story

**As a** stockroom clerk (P-005),
**I want to** open an expected delivery on my phone and check off items as I unload them, comparing against ordered quantities,
**So that** short-shipped or over-shipped items are caught on the spot, at the truck, not discovered days later during a count.

## Acceptance Criteria

- [ ] Given a purchase order or expected delivery exists ([[US-048]]), when I open it in the companion app, then I see each expected item and quantity, and can scan or tap to mark quantities received against each line.
- [ ] Given a received quantity doesn't match the expected quantity, when I confirm the line, then the discrepancy is flagged and I can add a note (e.g. "2 broken in transit") before finalizing.
- [ ] Given I have no matching PO for a delivery (informal/cash supplier), when I choose "receive without PO," then I can still log a straightforward stock-in ([[US-031]]) with supplier name, quantity, and cost.
- [ ] Given I finish receiving, when I submit, then stock levels update immediately for received items, and any short-shipped lines remain visible as "outstanding" against that PO for follow-up.

## Notes

Distinct from [[US-031]] in that it's the mobile, PO-comparison-driven receiving flow rather than a generic manual stock-in. Depends on [[US-047]] and [[US-048]] existing for the PO-matched path, but the no-PO fallback works standalone.
