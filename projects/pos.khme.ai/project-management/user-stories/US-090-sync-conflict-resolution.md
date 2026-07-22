---
id: US-090
title: "Sync conflict resolution (same item edited on two devices)"
slug: "sync-conflict-resolution"
personas: [P-008, P-004]
epic: "Sync, Performance & Edge Cases"
priority: "must-have"
complexity: "L"
tags: [sync, offline, conflict]
---

# US-090: Sync conflict resolution (same item edited on two devices)

## User Story

**As a** multi-store operator (P-004) running two devices on one store,
**I want to** have the app sensibly resolve conflicts when the same item is edited offline on both devices,
**So that** I don't lose data or end up with corrupted stock counts.

## Acceptance Criteria

- [ ] Given the same item's price is edited offline on Device A and Device B before either syncs, when both come back online, then the app applies a deterministic resolution rule (last-write-wins by timestamp) and surfaces a "conflict resolved" note in the item's audit history.
- [ ] Given the same item's stock quantity is decremented by separate concurrent offline sales on two devices, when both sync, then stock deltas are summed (not overwritten) so no sold inventory is silently dropped or double-counted.
- [ ] Given a conflict was auto-resolved, when the store owner views the audit trail, then they can see both original values and which one won, with device and timestamp attribution.

## Notes

Depends on US-089 and US-083 (multi-device). Stock quantity conflicts must use delta-merge, not last-write-wins, to avoid the inventory equivalent of a double-charge bug class. Related: audit trail feature (Cash & Audit epic, other agent's range).
