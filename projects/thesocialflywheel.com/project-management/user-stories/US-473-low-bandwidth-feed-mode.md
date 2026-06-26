---
id: US-473
title: "Browse feed in low-bandwidth mode"
slug: low-bandwidth-feed-mode
personas: [P-008, P-006]
epic: "Feed & Ranking"
priority: should-have
complexity: medium
tags: [low-bandwidth, performance, accessibility, media]
---

# US-473: Browse Feed in Low-Bandwidth Mode

## User Story

**As a** quiet consumer (P-006)
**I want to** enable a reduced-media feed mode
**So that** the app remains fast and usable on a slow or metered connection

## Acceptance Criteria

- **Given** I enable "Low bandwidth mode" in Settings
  **When** the feed loads
  **Then** images appear as blurred placeholders and videos do not autoplay; only text and avatars load by default

- **Given** low-bandwidth mode is active
  **When** I tap a placeholder image
  **Then** only that image loads on demand

- **Given** my device detects a connection below 2G speeds
  **When** I haven't set a manual preference
  **Then** the app prompts: "Slow connection detected — enable low-bandwidth mode?" with Yes/Not now options

## Notes
Low-bandwidth mode is distinct from Data Saver (which also compresses API payloads).
