---
id: US-924
title: "Text-First Swipe Cards on Low Bandwidth"
slug: low-bandwidth-swipe-lane
personas: [P-010]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: medium
tags: [swipe, bandwidth, text-first, match, performance]
---

# US-924: Text-First Swipe Cards on Low Bandwidth

## User Story

**As a** skeptical switcher exploring the Swipe-to-Match lane on a slow connection
**I want to** see profile information immediately even if profile photos haven't loaded yet
**So that** I can decide whether to swipe left or right without waiting for images

## Acceptance Criteria

- **Given** I open the Swipe-to-Match lane on a connection under 2 Mbps
  **When** a profile card renders
  **Then** the user's name, shared interests, and bio text appear immediately while the photo loads in the background

- **Given** a profile photo has not loaded after 3 seconds
  **When** the card is displayed
  **Then** a generated initial avatar placeholder is shown so the card layout does not feel broken

## Notes
Preload text metadata for the next 3 cards before the user reaches them. Photo blur-up technique (tiny placeholder → full) preferred over empty box.
