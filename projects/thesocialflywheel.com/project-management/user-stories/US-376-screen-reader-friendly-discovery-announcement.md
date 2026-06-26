---
id: US-376
title: "Screen Reader Friendly Discovery Announcement"
slug: screen-reader-friendly-discovery-announcement
personas: [P-006]
epic: "Discovery Engine"
priority: must-have
complexity: low
tags: [discovery, accessibility, screen-reader]
---

# US-376: Screen Reader Friendly Discovery Announcement

## User Story

**As a** Quiet Consumer using a screen reader
**I want to** have discovery items announced clearly and distinctly from regular feed posts
**So that** I always know when I am encountering discovery content versus content from my mutuals

## Acceptance Criteria

- **Given** a screen reader is active on my device
  **When** focus moves to a discovery item in the feed
  **Then** the screen reader announces "Discovery item" before reading the post content and author

- **Given** a discovery item has a surfacing reason attached
  **When** the screen reader announces the item
  **Then** the surfacing reason is announced after the post content without requiring an additional interaction

## Notes
Use ARIA live regions or role="article" with aria-label containing the discovery prefix to achieve this without custom screen reader hacks.
