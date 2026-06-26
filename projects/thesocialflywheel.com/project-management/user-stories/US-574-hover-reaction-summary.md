---
id: US-574
title: "Hover to See Reaction Summary on Desktop"
slug: hover-reaction-summary
personas: [P-003]
epic: "Reactions & Engagement"
priority: could-have
complexity: low
tags: [reactions, hover, tooltip, desktop]
---

# US-574: Hover to See Reaction Summary on Desktop

## User Story

**As a** Social Connector on desktop
**I want to** hover over a reaction count to see a quick summary of who reacted
**So that** I can identify engagement from my close mutuals without opening the full reactor list

## Acceptance Criteria

- **Given** I hover over a reaction count on desktop
  **When** the tooltip appears (after 300 ms delay)
  **Then** it shows up to 5 names from my 1st-degree mutuals who used that emoji

- **Given** fewer than 5 first-degree mutuals reacted
  **Then** the tooltip fills remaining slots with 2nd-degree names, or shows a count-only fallback

## Notes
Not available on touch devices. Tooltip must meet WCAG 2.1 AA contrast requirements. Keyboard focus on the count element also triggers the tooltip.
