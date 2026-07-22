---
id: US-063
title: "Shift Open"
slug: "shift-open"
personas: [P-003, P-002]
epic: "Staff & Admin"
priority: "must-have"
complexity: "S"
tags: [staff, shift, cash-management]
---

# US-063: Shift Open

## User Story

**As a** cashier (P-003),
**I want to** formally open my shift when I start work, tying my staff account to a drawer count and a start time,
**So that** everything I do afterward is scoped to a clearly bounded shift I can be held accountable for — and no more.

## Acceptance Criteria

- [ ] Given a cashier logs in via PIN per [[US-060]] and no shift is currently open on that register, when they tap "Start Shift," then they are taken directly into the [[US-051]] drawer-open count flow.
- [ ] Given the drawer count is submitted, when the shift starts, then the app records shift start time, staff ID, and register ID, and the sell screen becomes active.
- [ ] Given a shift is already open on a register under a different staff member, when another cashier logs in, then the app prevents starting a second concurrent shift on the same register and prompts to hand it over instead.
- [ ] Given a cashier's shift is open, when they navigate away or the app backgrounds, then the shift remains open until explicitly closed (per [[US-064]]) or force-ended by a manager.

## Notes

Depends on [[US-051]] and [[US-060]]. One register = one active shift at a time; handover flow is [[US-064]].
