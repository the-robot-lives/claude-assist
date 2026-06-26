---
id: US-462
title: "Pull to refresh the feed"
slug: pull-to-refresh-feed
personas: [P-003, P-006]
epic: "Feed & Ranking"
priority: must-have
complexity: low
tags: [refresh, feed, interaction]
---

# US-462: Pull to Refresh the Feed

## User Story

**As a** social connector (P-003)
**I want to** pull down at the top of the feed to refresh it
**So that** I can load new posts on demand without navigating away

## Acceptance Criteria

- **Given** I am at the top of the home feed
  **When** I pull down and release
  **Then** a loading indicator appears and the feed reloads with newly published posts inserted at the top

- **Given** a refresh completes and there are no new posts
  **When** the feed settles
  **Then** a brief "You're up to date" message appears and the existing feed remains unchanged

## Notes
Pull-to-refresh is distinct from the new-post indicator (US-463); both can coexist.
