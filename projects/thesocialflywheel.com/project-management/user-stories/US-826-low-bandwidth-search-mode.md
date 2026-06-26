---
id: US-826
title: "Low-Bandwidth Search Mode"
slug: low-bandwidth-search-mode
personas: [P-008]
epic: "Search & Find"
priority: should-have
complexity: medium
tags: [search, low-bandwidth, performance, accessibility]
---

# US-826: Low-Bandwidth Search Mode

## User Story

**As a** accessibility-first user on a slow connection
**I want to** have search work without loading heavy assets
**So that** I can find content even on a poor network

## Acceptance Criteria

- **Given** low-bandwidth mode is active (detected automatically or enabled in Settings)
  **When** I search
  **Then** result cards render as text-only with no avatar images or inline media loaded

- **Given** low-bandwidth mode is active
  **When** I explicitly click "Load image" on a specific card
  **Then** only that card's image is fetched on demand

## Notes
Low-bandwidth mode can be toggled manually in Accessibility Settings independent of connection quality detection.
