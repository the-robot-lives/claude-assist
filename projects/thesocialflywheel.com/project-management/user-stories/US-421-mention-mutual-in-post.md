---
id: US-421
title: "Mention a mutual in a post"
slug: mention-mutual-in-post
personas: [P-003]
epic: "Posting & Content Creation"
priority: must-have
complexity: low
tags: [mention, mutuals, notification, social]
---

# US-421: Mention a Mutual in a Post

## User Story

**As a** Social Connector
**I want to** @mention one of my mutuals in my post
**So that** they are notified and drawn into the conversation

## Acceptance Criteria

- **Given** I am composing a post
  **When** I type "@" followed by at least two characters
  **Then** a dropdown shows matching mutuals I can select

- **Given** I mention a mutual and publish
  **When** the post goes live
  **Then** the mentioned mutual receives a notification with a link to the post

## Notes
Only mutuals (symmetric connections) can be mentioned; non-mutual suggestions are not shown.
