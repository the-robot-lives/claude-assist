---
id: US-707
title: "Notify User of Reaction on Their Post"
slug: reaction-on-post
personas: [P-006]
epic: "Notifications"
priority: should-have
complexity: low
tags: [reactions, notifications, engagement]
---

# US-707: Notify User of Reaction on Their Post

## User Story

**As a** Quiet Consumer
**I want to** receive a low-priority notification when my posts receive reactions
**So that** I can gauge how my content lands without needing to actively check

## Acceptance Criteria

- **Given** I have reaction notifications set to low-priority
  **When** a user reacts to my post
  **Then** the reaction is queued and delivered in a batched summary at most once per hour reading "Your post received [N] reactions"

- **Given** I have reaction notifications disabled
  **When** users react to my posts
  **Then** no notifications are sent and reaction counts update silently in the feed

## Notes
Individual reaction notifications (one per reaction) should not be the default to avoid flooding quiet users.
