---
id: US-493
title: "Respect system font size in the feed"
slug: feed-respects-system-font-size
personas: [P-008, P-006]
epic: "Feed & Ranking"
priority: must-have
complexity: low
tags: [accessibility, font-size, dynamic-type, feed]
---

# US-493: Respect System Font Size in the Feed

## User Story

**As an** accessibility-first user (P-008)
**I want to** have the feed automatically use my system font size setting
**So that** post text is readable without me adjusting anything in the app

## Acceptance Criteria

- **Given** I set my OS font size to "Large" (e.g., iOS Dynamic Type XXL)
  **When** I open the feed
  **Then** post text, author names, channel labels, and degree badges all scale to the selected size

- **Given** an oversized font is set
  **When** a post preview renders
  **Then** the layout reflows gracefully without truncating interactive controls or overlapping degree badges

## Notes
Minimum accessible font size in the feed is 14 sp; no feed element should use a fixed pixel font size.
