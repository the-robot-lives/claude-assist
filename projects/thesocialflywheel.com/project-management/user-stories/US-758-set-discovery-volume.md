---
id: US-758
title: "Set Discovery Volume"
slug: set-discovery-volume
personas: [P-006]
epic: "Settings & Preferences"
priority: should-have
complexity: low
tags: [content-preferences, discovery, volume, feed]
---

# US-758: Set Discovery Volume

## User Story

**As a** quiet consumer
**I want to** control how many discovery posts appear per session
**So that** my feed stays focused and does not feel overwhelming.

## Acceptance Criteria

- **Given** I open Content Preferences
  **When** I set discovery volume to "Low (5 posts per session)"
  **Then** the Discovery lane surfaces at most 5 new posts each time I open the app.

## Notes
Volume options are Low (5), Medium (15, default), and High (30). The cap resets at session start.
