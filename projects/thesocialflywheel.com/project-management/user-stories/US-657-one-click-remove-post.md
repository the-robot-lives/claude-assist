---
id: US-657
title: "One-Click Remove Post"
slug: one-click-remove-post
personas: [P-007]
epic: "Moderation & Reporting"
priority: must-have
complexity: low
tags: [moderation, mod-actions]
---

# US-657: One-Click Remove Post

## User Story

**As a** channel moderator
**I want to** remove a reported post in a single action from the report card
**So that** harmful content is hidden immediately without requiring me to navigate to the post first

## Acceptance Criteria

- **Given** I am viewing a report card with an attached post
  **When** I click "Remove Post"
  **Then** the post is hidden from all channel members instantly, the report is marked resolved, and both the reporter and poster receive system notifications

- **Given** the post is removed
  **When** the poster's notification is sent
  **Then** it states which channel rule was cited (if selected) without revealing the reporter's identity

## Notes
Removed content should be soft-deleted and retained for appeals purposes, not permanently destroyed.
