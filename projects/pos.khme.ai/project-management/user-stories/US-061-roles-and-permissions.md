---
id: US-061
title: "Roles and Permissions (Cashier / Manager / Owner)"
slug: "roles-and-permissions"
personas: [P-002, P-004]
epic: "Staff & Admin"
priority: "must-have"
complexity: "M"
tags: [staff, permissions, roles]
---

# US-061: Roles and Permissions (Cashier / Manager / Owner)

## User Story

**As a** minimart owner (P-002),
**I want to** assign each staff member a role — cashier, manager, or owner — with a fixed set of allowed actions,
**So that** I control who can do sensitive things (voids, refunds, price overrides, staff management) without having to babysit every register action myself.

## Acceptance Criteria

- [ ] Given an owner is creating or editing a staff account, when they assign a role, then the app applies a predefined permission set (cashier: sell, basic returns within limits; manager: voids, refunds, price overrides, drawer oversight; owner: everything including staff and store settings).
- [ ] Given a staff member attempts an action outside their role's permissions, when they try, then the app blocks it and offers a manager-PIN override path per [[US-062]] where applicable.
- [ ] Given an owner views a staff member's profile, when they change the role, then the change takes effect immediately (including on any device where that staff member is currently logged in) and is logged to the audit trail.
- [ ] Given a store has more than one owner-role account, when any owner-role account edits permissions, then the action itself is logged (owners aren't exempt from the audit trail).

## Notes

Default role permission sets should be sensible out of the box for a novice owner like P-001 who won't want to configure granular permissions. Depends on [[US-060]]. Feeds [[US-062]].
