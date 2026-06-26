---
id: US-498
title: "Share a feed post to another channel or externally"
slug: share-post-from-feed
personas: [P-009, P-003]
epic: "Feed & Ranking"
priority: should-have
complexity: low
tags: [share, post, feed, social]
---

# US-498: Share a Feed Post to Another Channel or Externally

## User Story

**As a** creator (P-009)
**I want to** share a post I see in the feed to one of my other channels or via an external share sheet
**So that** I can surface good content to different audiences

## Acceptance Criteria

- **Given** I tap the share icon on a feed post
  **When** the share sheet opens
  **Then** I can choose "Share to channel" (selecting from my subscribed channels) or "Share externally" (native OS share sheet)

- **Given** I share a post to a channel
  **When** the action completes
  **Then** the post appears in the target channel with a "Shared by @me" attribution and a link back to the original

- **Given** the original post author has set "No external sharing"
  **When** I open the share sheet
  **Then** the "Share externally" option is greyed out with a tooltip "Author restricted external sharing"

## Notes
Internal channel shares count the sharer's degree for ranking purposes in the target channel's feed.
