---
id: US-056
title: "Audit Trail of Every Mutation"
slug: "audit-trail-every-mutation"
personas: [P-002, P-004]
epic: "Cash & Audit"
priority: "must-have"
complexity: "L"
tags: [audit, trust, accountability]
---

# US-056: Audit Trail of Every Mutation

## User Story

**As a** minimart owner (P-002),
**I want to** have every price change, void, refund, stock adjustment, and drawer event automatically logged with who did it, when, and exactly what changed,
**So that** I can leave staff alone with the till and still have a full accounting of anything that goes wrong, without watching over their shoulder.

## Acceptance Criteria

- [ ] Given any staff member performs a price change, void, refund, stock adjustment, or drawer action, when the action completes, then an audit event is written capturing staff ID, store ID, timestamp, action type, before-value, after-value, and any linked transaction/item ID.
- [ ] Given the app is offline when a mutation occurs, when connectivity resumes, then the queued audit event syncs with its original local timestamp preserved (not the sync time).
- [ ] Given an audit event is written, when any user (including an owner or manager) attempts to edit or delete it, then the system rejects the action — audit events are write-once.
- [ ] Given a mutation fails partway (e.g. app crash after a void but before drawer update), when the app recovers, then the audit trail reflects only the mutation(s) that actually completed, with no orphaned or duplicate entries.

## Notes

This is the foundation the rest of the Cash & Audit epic depends on — [[US-051]], [[US-052]], [[US-054]], [[US-055]], [[US-057]], [[US-058]] all write into this log. Cross-epic: register-side voids/refunds originate in the Checkout epic (US-001–025); stock adjustments originate in the Inventory epic (US-026–050) — both must call into this shared audit write path rather than logging separately.
