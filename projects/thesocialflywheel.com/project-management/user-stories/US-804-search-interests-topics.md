---
id: US-804
title: "Search Interest Topics"
slug: search-interests-topics
personas: [P-002]
epic: "Search & Find"
priority: must-have
complexity: low
tags: [search, interests, topics, discovery]
---

# US-804: Search Interest Topics

## User Story

**As a** niche enthusiast
**I want to** search for interest topics by keyword
**So that** I can discover channels and communities centered on subjects I care about

## Acceptance Criteria

- **Given** I type a topic name in the global search bar
  **When** I select the Interests filter
  **Then** matching interest topics with subscriber counts appear in ranked order

- **Given** I click an interest topic in results
  **When** the page loads
  **Then** I see channels and posts tagged with that interest

## Notes
Topics with zero subscribers should be deprioritized but still discoverable.
