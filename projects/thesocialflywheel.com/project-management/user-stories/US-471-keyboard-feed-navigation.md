---
id: US-471
title: "Navigate feed with keyboard shortcuts"
slug: keyboard-feed-navigation
personas: [P-008, P-006]
epic: "Feed & Ranking"
priority: should-have
complexity: medium
tags: [accessibility, keyboard, navigation, feed]
---

# US-471: Navigate Feed with Keyboard Shortcuts

## User Story

**As an** accessibility-first user (P-008)
**I want to** move through feed posts using keyboard shortcuts
**So that** I can browse without a mouse or touch screen

## Acceptance Criteria

- **Given** I am viewing the home feed on a device with a keyboard
  **When** I press the J key (or Down arrow)
  **Then** focus advances to the next post and the post is scrolled into view

- **Given** a post has focus
  **When** I press B
  **Then** the post is bookmarked (equivalent to tapping the bookmark icon)

- **Given** a post has focus
  **When** I press H
  **Then** the post is hidden (equivalent to tapping "Hide")

## Notes
A keyboard shortcut reference sheet is accessible via "?" key from anywhere in the feed.
