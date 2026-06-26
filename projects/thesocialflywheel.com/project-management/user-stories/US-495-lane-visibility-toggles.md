---
id: US-495
title: "Toggle individual lane visibility in the feed"
slug: lane-visibility-toggles
personas: [P-006, P-004]
epic: "Feed & Ranking"
priority: should-have
complexity: low
tags: [lane, visibility, toggle, feed-control]
---

# US-495: Toggle Individual Lane Visibility in the Feed

## User Story

**As a** quiet consumer (P-006)
**I want to** toggle each feed lane (Opposing-Views, Discovery, Swipe-to-Match) on or off independently
**So that** I have granular control over what types of content appear without adjusting percentage sliders

## Acceptance Criteria

- **Given** I open Feed Preferences
  **When** I toggle "Opposing-Views" to off
  **Then** the Opposing-Views posts disappear from the home feed and the slider for that lane greys out

- **Given** all non-Mutuals lanes are toggled off
  **When** the feed loads
  **Then** only mutual posts appear, equivalent to "Mutuals only" mode

- **Given** I re-enable a lane
  **When** the feed next refreshes
  **Then** posts from that lane return at their default ratio

## Notes
Lane toggles persist across sessions and sync to the user's profile preferences.
