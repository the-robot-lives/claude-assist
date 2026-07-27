---
id: US-105
title: "Resolve a suspected duplicate flag"
slug: resolve-suspected-duplicate-flag
personas: [P-001, P-002, P-006]
epic: "Sync & Multi-Device"
priority: must-have
complexity: medium
tags: [sync, review]
---

# US-105: Resolve a suspected duplicate flag

## User Story

**As a** user reviewing my timeline
**I want to** see when the system suspects two records were created for the same work
**So that** I decide whether to keep both, dismiss the flag, or merge them, instead of the system guessing for me

## Acceptance Criteria

- **Given** two live spans in the same workspace have different ids, start times within 120 seconds of each other, ends that are both null or within 120 seconds of each other, the same resolved project (or both null), and `canon()` of their titles equal or either title empty
  **When** the second span is created or updated
  **Then** the server appends a `suspected_duplicate` review reason to BOTH rows, each citing the other in `related_id`, and sets `review_state: needs_review` on both - it never merges, deletes, or hides either row

- **Given** a `suspected_duplicate` flag is showing on a span
  **When** I set its resolution to `accepted`, `dismissed`, or `merged`
  **Then** that is the ONLY way the flag clears - the server never auto-resolves it on its own

- **Given** a workspace produces a pathological number of same-titled spans inside one 24-hour window
  **When** duplicate detection runs
  **Then** flag generation is capped at 20 pairs per mutation so review noise stays bounded

## Notes

See docs/SYNC-PROTOCOL.md §8.3 for the exact detection criteria and §5 (design commitment 5: "the server flags, the user resolves"). This is a sibling of US-106 (billing overlap) - same design principle, different trigger condition; do not conflate the two in an implementation.
