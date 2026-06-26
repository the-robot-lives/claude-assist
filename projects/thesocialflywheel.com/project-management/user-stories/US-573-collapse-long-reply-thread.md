---
id: US-573
title: "Collapse a Long Reply Thread"
slug: collapse-long-reply-thread
personas: [P-006]
epic: "Reactions & Engagement"
priority: should-have
complexity: low
tags: [threading, collapse, readability]
---

# US-573: Collapse a Long Reply Thread

## User Story

**As a** Quiet Consumer
**I want to** collapse a long reply thread
**So that** I can return to browsing my feed without scrolling past dozens of replies

## Acceptance Criteria

- **Given** a post has an open thread with more than 5 replies
  **When** I tap "Collapse thread"
  **Then** all replies hide and the post returns to its compact feed form with a reply count badge

- **Given** a collapsed thread
  **When** I tap "Expand thread"
  **Then** all replies re-appear without a network reload

## Notes
Collapsed state persists for the current session. The thread auto-expands when I navigate directly to the post via a notification.
