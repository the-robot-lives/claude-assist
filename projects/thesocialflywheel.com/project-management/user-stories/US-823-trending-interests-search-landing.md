---
id: US-823
title: "Trending Interests on Search Landing Page"
slug: trending-interests-search-landing
personas: [P-002]
epic: "Search & Find"
priority: could-have
complexity: medium
tags: [search, trending, interests, discovery]
---

# US-823: Trending Interests on Search Landing Page

## User Story

**As a** niche enthusiast
**I want to** see trending interest topics on the search landing page before I type
**So that** I can discover what's popular right now without knowing what to search for

## Acceptance Criteria

- **Given** I open the search bar and have not typed anything
  **When** the landing state renders
  **Then** a "Trending" section shows the top 10 rising interest topics within my network

- **Given** trending topics are shown
  **When** I click one
  **Then** an interest search for that topic runs immediately

## Notes
Trending list refreshes every 15 minutes; stale data should not be shown more than 30 minutes old.
