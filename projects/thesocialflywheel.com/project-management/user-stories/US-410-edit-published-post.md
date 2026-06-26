---
id: US-410
title: "Edit a published post"
slug: edit-published-post
personas: [P-009]
epic: "Posting & Content Creation"
priority: must-have
complexity: medium
tags: [edit, post, correction]
---

# US-410: Edit a Published Post

## User Story

**As a** Creator
**I want to** edit the text of a post I have already published
**So that** I can correct mistakes or update information without deleting and reposting

## Acceptance Criteria

- **Given** I am viewing my own published post
  **When** I tap the kebab menu and select Edit
  **Then** the composer opens with the current post content pre-filled

- **Given** I save edits to a published post
  **When** other users view the post
  **Then** an "Edited" label and edit timestamp are shown below the post

## Notes
Editing does not re-trigger propagation. Media attachments can be reordered but not changed post-publish.
