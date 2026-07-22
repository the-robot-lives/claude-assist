---
id: US-025
title: "Partial payments / credit tab for regulars"
slug: "partial-payment-credit-tab"
personas: [P-001, P-008]
epic: "Payments & Currency"
priority: "could-have"
complexity: "L"
tags: [credit, partial-payment, regulars]
---

# US-025: Partial Payments / Credit Tab for Regulars

## User Story

**As a** rural pharmacy owner (P-008),
**I want to** let a trusted regular customer pay part of a sale now and the rest later on a running tab,
**So that** I can extend informal credit the way I already do on paper, without losing track of who owes what.

## Acceptance Criteria

- [ ] Given a customer is registered as a known regular, when I complete a sale with partial payment, then the unpaid balance is recorded against that customer's tab with the original sale reference.
- [ ] Given a customer has an open tab, when they return to pay it down, then I can apply a payment against the tab balance (in either currency) and see the updated balance immediately.
- [ ] Given a tab balance exists, when I view the customer's record, then I see the full history of charges and payments with dates, distinct from regular sales reporting.

## Notes

Flagged could-have for v1 per the product README's cash-first principle; depends on a lightweight customer/regulars record, which may need coordination with the Reporting epic (US-051-075). Related: US-019.
