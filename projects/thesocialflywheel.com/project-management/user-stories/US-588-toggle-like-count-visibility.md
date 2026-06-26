---
id: US-588
title: "Toggle Like-Count Visibility on My Posts"
slug: toggle-like-count-visibility
personas: [P-009]
epic: "Reactions & Engagement"
priority: could-have
complexity: low
tags: [creator, counts, privacy]
---

# US-588: Toggle Like-Count Visibility on My Posts

## User Story

**As a** Creator
**I want to** hide the reaction count on my posts from public view
**So that** my audience focuses on content rather than popularity metrics

## Acceptance Criteria

- **Given** I open options on my post
  **When** I toggle "Hide reaction counts"
  **Then** the public count is hidden from viewers; I still see the count in my private analytics dashboard

- **Given** counts are hidden
  **When** a viewer reacts
  **Then** their reaction is recorded normally but the numeric total remains hidden from all viewers including me in feed view

## Notes
Creator can re-enable counts at any time. The toggle is per-post, not a global setting.
