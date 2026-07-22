---
id: US-066
title: "Deactivate Staff Account"
slug: "deactivate-staff-account"
personas: [P-002, P-004]
epic: "Staff & Admin"
priority: "must-have"
complexity: "S"
tags: [staff, security, offboarding]
---

# US-066: Deactivate Staff Account

## User Story

**As a** minimart owner (P-002),
**I want to** immediately deactivate a staff member's account and PIN when they leave or I no longer trust them,
**So that** they can't log into any register at any store the moment I decide to cut access, without deleting their historical audit trail.

## Acceptance Criteria

- [ ] Given an owner selects a staff member and taps "Deactivate," when confirmed, then that staff member's PIN is rejected on every register at every store they were assigned to, effective immediately (or on next sync for offline registers).
- [ ] Given a staff member is deactivated while a shift is open under their account, when deactivation is confirmed, then the app forces that shift to close and prompts a manager to complete the [[US-052]] reconciliation on their behalf.
- [ ] Given a staff member is deactivated, when the owner views the audit log, then all their historical events remain fully intact and attributed to them — deactivation does not delete or anonymize history.
- [ ] Given an owner deactivates their own last remaining owner-role account, when they attempt it, then the app blocks the action to prevent a store from being left without an owner.

## Notes

Deactivation is a status flag, not a delete — audit integrity per [[US-058]] requires historical attribution to survive offboarding. Depends on [[US-060]], [[US-061]].
