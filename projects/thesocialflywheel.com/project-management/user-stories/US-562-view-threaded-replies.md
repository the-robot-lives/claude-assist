---
id: US-562
title: "View Threaded Replies on a Post"
slug: view-threaded-replies
personas: [P-001, P-003]
epic: "Reactions & Engagement"
priority: must-have
complexity: medium
tags: [threading, replies, discussion]
---

# US-562: View Threaded Replies on a Post

## User Story

**As a** Bridge-Builder
**I want to** see replies threaded beneath the original post
**So that** I can follow a conversation without losing context

## Acceptance Criteria

- **Given** a post has replies
  **When** I open the post detail view
  **Then** top-level replies appear beneath the post and nested replies are visually indented

- **Given** a thread has more than 10 replies
  **When** I view the post
  **Then** I see the top 3 replies and a "View all N replies" control to load the rest

## Notes
Thread depth is capped at 5 levels to avoid infinite nesting UX. Deeper replies use "Continue thread" (US-572).
