---
id: US-411
title: "Delete a post"
slug: delete-post
personas: [P-009]
epic: "Posting & Content Creation"
priority: must-have
complexity: low
tags: [delete, post, moderation]
---

# US-411: Delete a Post

## User Story

**As a** Creator
**I want to** permanently delete one of my posts
**So that** it is removed from all feeds and no longer visible to any users

## Acceptance Criteria

- **Given** I am viewing my own published post
  **When** I select Delete and confirm the action
  **Then** the post is removed from all feeds within 30 seconds and the deletion is irreversible

- **Given** a post with replies exists
  **When** I delete the original post
  **Then** replies remain visible but are shown under a "[Post deleted]" placeholder

## Notes
Deletion is permanent; no soft-delete recovery for end users.
