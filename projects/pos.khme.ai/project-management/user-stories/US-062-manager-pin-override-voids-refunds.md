---
id: US-062
title: "Manager PIN Override for Voids and Refunds"
slug: "manager-pin-override-voids-refunds"
personas: [P-002, P-003]
epic: "Staff & Admin"
priority: "must-have"
complexity: "M"
tags: [staff, permissions, audit]
---

# US-062: Manager PIN Override for Voids and Refunds

## User Story

**As a** cashier (P-003),
**I want to** call over a manager to approve a void or refund with their own PIN when I don't have permission to do it myself,
**So that** the customer's issue gets resolved on the spot, and there's a clear record of who authorized it — protecting me from suspicion and the owner from unauthorized giveaways.

## Acceptance Criteria

- [ ] Given a cashier attempts a void, refund, or other manager-gated action, when their role lacks permission, then the app prompts for a manager or owner PIN instead of blocking the action outright.
- [ ] Given a manager enters their PIN to approve, when it's valid and that manager has the required permission, then the action proceeds and is logged with both the cashier's ID (who initiated) and the manager's ID (who approved).
- [ ] Given an invalid manager PIN is entered, when the attempt fails, then the action is blocked and the failed attempt itself is logged to the audit trail.
- [ ] Given a payout exceeds the store-configured limit per [[US-055]], when it's submitted, then the same manager-approval flow applies.

## Notes

Depends on [[US-060]] and [[US-061]]. This is the enforcement mechanism referenced by [[US-056]] audit trail and [[US-055]] payouts — write it once, reuse across all gated actions rather than duplicating approval logic per feature.
