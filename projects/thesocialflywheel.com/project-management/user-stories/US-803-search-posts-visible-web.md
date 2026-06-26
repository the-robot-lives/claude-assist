---
id: US-803
title: "Search Posts Within My Visible Web"
slug: search-posts-visible-web
personas: [P-006]
epic: "Search & Find"
priority: must-have
complexity: medium
tags: [search, posts, visibility, web]
---

# US-803: Search Posts Within My Visible Web

## User Story

**As a** quiet consumer
**I want to** search posts and only see ones within my visible web
**So that** I don't encounter content from channels or people I've blocked or can't access

## Acceptance Criteria

- **Given** I search for a keyword
  **When** I filter to Posts
  **Then** only posts from channels I can access and users who haven't blocked me appear

- **Given** a channel is private and I am not a member
  **When** I search posts
  **Then** posts from that channel are excluded from results

## Notes
Visibility enforcement happens server-side; the client never receives excluded records.
