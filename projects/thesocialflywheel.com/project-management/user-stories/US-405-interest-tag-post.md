---
id: US-405
title: "Interest-tag a post"
slug: interest-tag-post
personas: [P-002]
epic: "Posting & Content Creation"
priority: must-have
complexity: medium
tags: [interests, tagging, reach, discovery]
---

# US-405: Interest-Tag a Post

## User Story

**As a** Niche Enthusiast
**I want to** tag my post with one or more interest channels
**So that** my content reaches mutuals and outer-degree users who follow those interests

## Acceptance Criteria

- **Given** I am composing a post
  **When** I open the interest-tag picker and select up to five interests
  **Then** the selected tags are shown as chips in the composer

- **Given** I publish a tagged post
  **When** the propagation engine runs
  **Then** users at 2nd–4th degrees who follow those interests receive the post in their interest-filtered lane

## Notes
Tags are searchable; user can also type to filter the list. Maximum 5 tags per post.
