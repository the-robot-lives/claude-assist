---
id: US-364
title: "Low-Bandwidth Text-Only Discovery"
slug: low-bandwidth-text-only-discovery
personas: [P-006]
epic: "Discovery Engine"
priority: should-have
complexity: low
tags: [discovery, low-bandwidth, accessibility]
---

# US-364: Low-Bandwidth Text-Only Discovery

## User Story

**As a** Quiet Consumer
**I want to** receive discovery items as text-only cards when I am on a slow connection
**So that** discovery content loads quickly and does not consume excessive data

## Acceptance Criteria

- **Given** my device reports a slow or metered connection (e.g., 2G/3G or Data Saver active)
  **When** the feed loads discovery items
  **Then** images and video within discovery cards are not fetched and placeholders are shown instead

- **Given** a text-only discovery card is displayed
  **When** I manually tap to load the media
  **Then** only that card's media is fetched on demand

## Notes
Text-only mode should also suppress autoplay video in discovery cards unconditionally on metered connections.
