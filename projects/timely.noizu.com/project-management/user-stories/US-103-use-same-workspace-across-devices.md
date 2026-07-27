---
id: US-103
title: "Use the same workspace across devices"
slug: use-same-workspace-across-devices
personas: [P-001, P-003, P-004]
epic: "Sync & Multi-Device"
priority: must-have
complexity: medium
tags: [sync, multi-device]
---

# US-103: Use the same workspace across devices

## User Story

**As a** user who works from both a Mac and a phone
**I want to** have the same clients, projects, and tasks resolve to the same records on every device
**So that** I don't end up with duplicate "Acme" clients just because I typed the name on two different keyboards

## Acceptance Criteria

- **Given** I create a client or project by name on my Mac while offline, and independently create the same name on my phone while it is also offline
  **When** both devices come online and push
  **Then** both computed the same deterministic id ahead of time and their creates merge into a single row with no manual reconciliation

- **Given** the same name is typed with different casing, padding, or a smart-quote apostrophe substituted by one device's autocorrect (for example "Bob's Diner" typed on a Mac vs. "Bob's Diner" auto-corrected on an iPhone)
  **When** both are canonicalized
  **Then** they resolve to the identical record - `canon()` runs identically on the server, on macOS/iOS, and on Android, and is pinned by the shared conformance fixture every implementation must pass before it is allowed to sync

- **Given** I rename a client on one device while another device is offline
  **When** the offline device later vivifies the OLD name
  **Then** it mints the still-valid old id and lands harmlessly on the renamed row; **when** it instead vivifies a NEW name matching the rename, the server returns a `duplicate_name` conflict and the device performs a reference rewrite rather than creating a second row

## Notes

See docs/SYNC-PROTOCOL.md §3.2 (deterministic ids), §3.3 (`canon()`), §6.2 (duplicate-name conflict and reference rewrite), and apps/shared/contracts/canon-fixtures.json (the executable conformance suite referenced above).
