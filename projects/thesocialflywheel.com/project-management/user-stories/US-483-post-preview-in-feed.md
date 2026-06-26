---
id: US-483
title: "See a rich post preview in the feed"
slug: post-preview-in-feed
personas: [P-006, P-009]
epic: "Feed & Ranking"
priority: must-have
complexity: medium
tags: [post-preview, feed, media, text]
---

# US-483: See a Rich Post Preview in the Feed

## User Story

**As a** quiet consumer (P-006)
**I want to** see a meaningful preview of each post (text excerpt, thumbnail, channel, author) without opening it
**So that** I can quickly decide whether to read the full post

## Acceptance Criteria

- **Given** a post contains text and an image
  **When** it appears in the feed
  **Then** the first 280 characters of text and a thumbnail image are shown, truncated with "Read more"

- **Given** a post contains only text
  **When** it appears in the feed
  **Then** up to 480 characters are shown before truncation

- **Given** a post is from the Opposing-Views lane
  **When** it renders in the feed
  **Then** the preview includes the "Opposing View" badge before the author name

## Notes
Video posts show a static thumbnail with a play-duration overlay; no autoplay in the feed.
