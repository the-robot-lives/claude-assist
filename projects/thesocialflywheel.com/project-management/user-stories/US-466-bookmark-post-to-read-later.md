---
id: US-466
title: "Bookmark a post to read later"
slug: bookmark-post-to-read-later
personas: [P-006, P-002]
epic: "Feed & Ranking"
priority: should-have
complexity: low
tags: [bookmark, save, post, later]
---

# US-466: Bookmark a Post to Read Later

## User Story

**As a** quiet consumer (P-006)
**I want to** bookmark posts while scrolling
**So that** I can revisit interesting content without losing it in the feed

## Acceptance Criteria

- **Given** I see a post in the feed
  **When** I tap the bookmark icon
  **Then** the post is saved to my Bookmarks collection and the icon fills to confirm

- **Given** I have bookmarked a post
  **When** I navigate to my Bookmarks page
  **Then** the post appears there with its original timestamp and author preserved

- **Given** I tap the bookmark icon on an already-bookmarked post
  **When** the action confirms
  **Then** the post is removed from Bookmarks and the icon reverts to unfilled

## Notes
Bookmarks are private by default and not visible to other users.
