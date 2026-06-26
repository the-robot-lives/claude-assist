---
id: US-608
title: "Block from Post Context Menu"
slug: block-from-post-context-menu
personas: [P-005]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: low
tags: [safety, blocking, ux]
---

# US-608: Block from Post Context Menu

## User Story

**As a** debate seeker
**I want to** block a user directly from the context menu on any of their posts
**So that** I can take safety action without navigating away from my current feed

## Acceptance Criteria

- **Given** I am viewing a post in any lane
  **When** I open the post's "..." context menu
  **Then** a "Block author" option is available

- **Given** I select "Block author" from the context menu
  **When** I confirm the action in the dialog
  **Then** the post is immediately hidden and the block takes effect

## Notes
Context-menu block uses the same default (direct-only) scope as profile-level block.
