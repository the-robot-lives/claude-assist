---
id: US-599
title: "Sync Engagement Across Devices"
slug: sync-engagement-across-devices
personas: [P-006]
epic: "Reactions & Engagement"
priority: should-have
complexity: medium
tags: [sync, multi-device, reactions, bookmarks]
---

# US-599: Sync Engagement Across Devices

## User Story

**As a** Quiet Consumer
**I want to** my reactions and bookmarks to sync across all my devices
**So that** I don't have to redo actions on my phone after engaging on the web app

## Acceptance Criteria

- **Given** I bookmark a post on my desktop
  **When** I open the mobile app within 30 seconds
  **Then** the bookmarked post appears in my Saved list on mobile

- **Given** I react to a post on mobile
  **When** I view the same post on desktop
  **Then** my reaction is shown as active with the correct emoji highlighted

## Notes
Sync is near-real-time via WebSocket push. Optimistic local state is used while the sync completes. Conflicts (same emoji reacted on two devices simultaneously) are idempotent — result is one reaction.
