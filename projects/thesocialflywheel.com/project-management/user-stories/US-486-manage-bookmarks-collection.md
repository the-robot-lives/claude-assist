---
id: US-486
title: "Manage a bookmarks collection"
slug: manage-bookmarks-collection
personas: [P-006, P-002]
epic: "Feed & Ranking"
priority: should-have
complexity: medium
tags: [bookmarks, collection, save, manage]
---

# US-486: Manage a Bookmarks Collection

## User Story

**As a** quiet consumer (P-006)
**I want to** view, search, and organise my bookmarked posts
**So that** I can find saved content easily when I'm ready to read it

## Acceptance Criteria

- **Given** I navigate to My Bookmarks
  **When** the page loads
  **Then** all bookmarked posts appear in reverse-save-order with the save date shown

- **Given** I have more than 20 bookmarks
  **When** I use the search bar in Bookmarks
  **Then** bookmarks are filtered in real time by author name or post text excerpt

- **Given** a bookmarked post's author has deleted the original post
  **When** I view My Bookmarks
  **Then** the deleted post is shown with a "[Post deleted]" notice but remains in my collection

## Notes
Bookmarks do not expire automatically; users must manually remove them.
