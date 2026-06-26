---
id: US-817
title: "Search Posts Within a Specific Channel"
slug: search-within-channel
personas: [P-002]
epic: "Search & Find"
priority: must-have
complexity: low
tags: [search, channel, in-channel, posts]
---

# US-817: Search Posts Within a Specific Channel

## User Story

**As a** niche enthusiast
**I want to** search within a single channel I am viewing
**So that** I can find past discussions without leaving the channel context

## Acceptance Criteria

- **Given** I am inside a channel
  **When** I use the in-channel search bar
  **Then** only posts within that channel matching my query appear

- **Given** in-channel search returns results
  **When** I click a result
  **Then** I am scrolled to and the post is highlighted in the channel timeline

## Notes
In-channel search is scoped to the current channel and ignores global type filters.
