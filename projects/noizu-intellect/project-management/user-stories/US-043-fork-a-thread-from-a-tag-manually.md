---
id: US-043
title: "Fork a thread from a tag manually"
slug: fork-a-thread-from-a-tag-manually
personas: [P-001, P-005]
epic: "Parallel-Path Execution"
priority: should-have
complexity: medium
tags: [checkout, fork, tag, manual]
---

# US-043: Fork a Thread from a Tag Manually

## User Story

**As a** researcher
**I want to** manually check out a new thread from any existing tag, outside of a Planner-driven path run
**So that** I can explore an alternate direction from a known-good checkpoint without waiting for or depending on the Planner's decomposition

## Acceptance Criteria

- **Given** a tag exists on a thread
  **When** I choose "checkout" on that tag
  **Then** a new thread is created whose message history, memories, and cognition state are copied/forked from exactly the tagged boundary, and the new thread links back to its source tag for provenance

- **Given** I check out a tag
  **When** the new thread is created
  **Then** it is not automatically a "path" (no Reviewer grading, no Picker workflow) — it behaves as an ordinary standalone thread unless I explicitly promote it into a run

- **Given** I check out the same tag twice
  **When** both checkouts exist
  **Then** each is an independent thread; edits or new messages in one never appear in the other (no shared mutable state post-fork)

- **Given** I check out a tag from a thread I don't have write access to but do have read access to
  **When** I attempt checkout
  **Then** the system either permits a read-only fork into my own workspace or denies it per project permissions, but never silently grants write access to the source thread

## Notes
This is the manual/ad-hoc counterpart to the Planner-automated fan-out in US-044; both use the same underlying tag/checkout primitive from US-042. Useful for Elias's repeatable-experiment workflows — checking out the same tag under different manual conditions to compare against a parallel-path run's own paths.
