---
id: US-067
title: "Multi-Store Staff Assignment"
slug: "multi-store-staff-assignment"
personas: [P-004]
epic: "Staff & Admin"
priority: "could-have"
complexity: "M"
tags: [staff, multi-store, permissions]
---

# US-067: Multi-Store Staff Assignment

## User Story

**As a** multi-store operator (P-004),
**I want to** assign a single staff member to work across more than one of my stores, with per-store roles if needed,
**So that** a trusted employee can cover shifts at whichever location needs them without me creating a duplicate account for each store.

## Acceptance Criteria

- [ ] Given an owner is editing a staff member, when they add a store assignment, then the staff member can log in with the same PIN at that store's registers and select which store's shift they're opening if assigned to more than one.
- [ ] Given a staff member holds different roles at different stores (e.g. manager at one, cashier at another), when they log in, then the permissions applied match the specific store they're working at, per [[US-061]].
- [ ] Given an owner removes a store assignment from a staff member, when saved, then their access to that store's registers is revoked immediately while access to remaining assigned stores is unaffected.
- [ ] Given the owner views [[US-065]] staff activity, when a multi-store staff member is selected, then activity is broken out per store with a combined total.

## Notes

Depends on [[US-060]], [[US-061]]. Lower priority than single-store staff management since most early adopters (market stalls, single-location minimarts) won't need it; matters most for P-004's use case.
