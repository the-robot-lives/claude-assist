---
id: US-836
title: "Trending Searches Section in Search Bar"
slug: trending-searches-section
personas: [P-002]
epic: "Search & Find"
priority: could-have
complexity: medium
tags: [search, trending, discovery, social]
---

# US-836: Trending Searches Section in Search Bar

## User Story

**As a** niche enthusiast
**I want to** see what search terms are trending among my network
**So that** I can join conversations gaining momentum before they peak

## Acceptance Criteria

- **Given** I open the search bar without typing
  **When** trending searches are available
  **Then** up to 5 trending terms appear under a "Trending in your network" heading

- **Given** I click a trending search term
  **When** the search runs
  **Then** results for that term appear using the current type filter

## Notes
Trending terms are derived from search activity within the user's 1st–3rd degree network only.
