---
id: US-083
title: "Adding a second device"
slug: "adding-second-device"
personas: [P-004, P-002]
epic: "Onboarding & Setup"
priority: "should-have"
complexity: "M"
tags: [onboarding, multi-device, sync]
---

# US-083: Adding a second device

## User Story

**As a** multi-store operator (P-004),
**I want to** add a second device to my existing store account,
**So that** I can run two registers (or a register plus companion app) at the same time.

## Acceptance Criteria

- [ ] Given a user is signed into an existing store on Device A, when they select "Add a device" and generate a pairing code, then entering that code on Device B links it to the same store within 2 minutes.
- [ ] Given two devices are linked to the same store, when either device makes a sale offline, then both devices reconcile via background sync once connectivity returns.
- [ ] Given a device is lost or decommissioned, when the owner revokes it from Settings > Devices, then that device can no longer sync or authenticate against the store.

## Notes

Depends on US-089 (offline-first sync) and feeds into US-090 (conflict resolution), since multi-device is what makes conflicts possible.
