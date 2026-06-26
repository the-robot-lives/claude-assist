---
id: US-855
title: "ARIA Labels on Post Cards with Degree Badges"
slug: aria-post-cards
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: medium
tags: [screen-reader, aria, degrees, wcag-2.2]
---

# US-855: ARIA Labels on Post Cards with Degree Badges

## User Story

**As a** screen-reader user
**I want to** have each post card carry a complete ARIA label including poster name, degree of connection, lane, and post snippet
**So that** I understand context without visual scanning

## Acceptance Criteria

- **Given** a post card in the feed
  **When** a screen reader focuses on it
  **Then** it announces "[Name], [N]th-degree moot, posted in [Channel], [Lane]: [snippet]"

- **Given** a degree badge icon is present
  **When** focus lands on it
  **Then** the badge has aria-label="Nth-degree connection" rather than just an icon

- **Given** a post has been boosted
  **When** focused by screen reader
  **Then** the label includes "boosted by [name]"

## Notes

Degree badge must not rely on color alone. Use aria-describedby to link the badge description to the post card container so context is available without redundant repetition on every inner element.
