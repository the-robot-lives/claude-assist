---
id: US-838
title: "Search Posts Scoped to Current Channel"
slug: search-posts-in-channel
personas: [P-002]
epic: "Search & Find"
priority: must-have
complexity: low
tags: [search, posts, channel, in-channel]
---

# US-838: Search Posts Scoped to Current Channel

## User Story

**As a** niche enthusiast
**I want to** run a keyword search limited to the channel I'm currently browsing
**So that** I can resurface specific past discussions without leaving the channel

## Acceptance Criteria

- **Given** I am in channel C and use the in-channel search bar
  **When** I type a keyword
  **Then** only posts in C matching that keyword appear — no cross-channel results bleed in

- **Given** in-channel results appear
  **When** I click a result
  **Then** the channel scrolls to and highlights that specific post in the timeline

## Notes
In-channel search is distinct from the global search bar and must not inherit global type filters.
