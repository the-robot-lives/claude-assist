---
id: US-085
title: "Disk-Full or Write Failure Never Corrupts the KB"
slug: atomic-writes-prevent-kb-corruption
personas: [P-008, P-006]
epic: "Resilience & Errors"
priority: must-have
complexity: high
tags: [resilience, atomic-writes, data-integrity]
---

# US-085: Disk-Full or Write Failure Never Corrupts the KB

## User Story

**As a** privacy-first consultant who runs robot-learns fully offline on a constrained machine
**I want to** be guaranteed that a disk-full condition or interrupted write never corrupts an existing KB file
**So that** I never lose or damage knowledge I've already captured due to a transient system issue

## Acceptance Criteria

- **Given** robot-learns is writing an update to a KB file
  **When** the write is interrupted by a crash, power loss, or disk-full error
  **Then** the original file on disk is either fully replaced with the new content or left completely untouched — never left half-written

- **Given** a write fails because the disk is full
  **When** robot-learns detects this
  **Then** it reports the disk-full condition clearly, discards the incomplete temp file, and leaves the KB in its last-good state

- **Given** atomic writes are implemented via write-to-temp-then-rename
  **When** I inspect the KB directory during a write
  **Then** I never observe a truncated or zero-byte version of an existing file, even under concurrent reads

- **Given** a previous crash left a stray temp file behind
  **When** robot-learns starts up
  **Then** it cleans up orphaned temp files without treating them as KB content

## Notes
This is the data-integrity foundation the quarantine flow in US-082 and the checkpointing in US-083 both assume is already in place.
