---
id: US-200
title: "Channel Interest Tag Discovery Path"
slug: channel-interest-tag-discovery-path
personas: [P-001]
epic: "Interest Channels"
priority: should-have
complexity: medium
tags: [channels, interest-tags, discovery, bridge-building, algorithm]
---

# US-200: Channel Interest Tag Discovery Path

## User Story

**As a** Bridge-Builder
**I want to** follow a chain of related interest tags from my current channels outward to discover progressively adjacent communities
**So that** I can explore a map of interests connecting my niche starting point to broader or complementary perspectives

## Acceptance Criteria

- **Given** I tap an interest tag on any channel card or info page
  **When** the tag detail view opens
  **Then** I see all channels using that tag plus a "Related Tags" section showing adjacent interest tags and the channel count behind each

- **Given** I am viewing a tag's detail page
  **When** I tap a related tag
  **Then** I navigate to that tag's detail page (breadcrumb trail maintained), allowing me to traverse the interest graph one step at a time

- **Given** I have traversed 3 or more tag hops
  **When** I view the breadcrumb trail
  **Then** I can tap any node in the trail to return to a previous tag without losing my exploration history for the session

## Notes
Related tags are derived from the platform's interest tag adjacency graph (same graph used in US-189). The breadcrumb trail is session-scoped and does not persist across sessions. Tag detail pages should surface both large popular channels and small niche channels (US-176).
