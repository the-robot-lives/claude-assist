---
id: US-107
title: "Sign in on a new device and pull history"
slug: sign-in-on-new-device-pull-history
personas: [P-001, P-004, P-005]
epic: "Sync & Multi-Device"
priority: must-have
complexity: medium
tags: [sync, multi-device]
---

# US-107: Sign in on a new device and pull history

## User Story

**As a** user setting up Timely on a new phone or a second Mac
**I want to** sign in and have my workspace's existing clients, projects, tasks, and time history arrive
**So that** a new device isn't a blank slate

## Acceptance Criteria

- **Given** I sign in on a device with no local mirror (watermark at 0)
  **When** it performs its first pull
  **Then** it pages through `/api/v1/sync/changes` from `since=0` until `has_more` is false, applies every row including tombstones, and persists the watermark atomically with the rows it covers, so a crash mid-bootstrap replays safely instead of losing data

- **Given** the new device is a phone with `local_only_screenshots` defaulted to true
  **When** history arrives
  **Then** screenshot METADATA syncs (captured time, active app name, the owning span, the vision-analysis status text) but image bytes do not - the device is fully usable without ever fetching a byte, per US-071

- **Given** the device instead tries to resume from an old watermark that predates the workspace's tombstone horizon (90 days minimum retained)
  **When** it requests changes since that watermark
  **Then** the server returns `410 cursor_too_old`, the device discards its mirror and re-bootstraps from `since=0`, and any of its OWN unpushed local mutations survive the rebootstrap untouched

## Notes

See docs/SYNC-PROTOCOL.md §5.1 (tombstone horizon), §7.1 (pull loop), and §10 (privacy and screenshot gating). Cross-reference US-071 (configure local-only storage) rather than duplicating it - that story owns the local-only-storage setting itself; this one is about a fresh device's default behavior on first sync.
