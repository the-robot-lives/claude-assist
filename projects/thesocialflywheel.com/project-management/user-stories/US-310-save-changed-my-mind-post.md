---
id: US-310
title: "Save a Post That Changed My Mind"
slug: save-changed-my-mind-post
personas: [P-001]
epic: "Opposing-Views Lane"
priority: should-have
complexity: low
tags: [opposing-views, save, reflection, no-reply]
---

# US-310: Save a Post That Changed My Mind

## User Story

**As a** bridge-builder
**I want to** save an opposing-view post to a private "Changed My Mind" collection without replying
**So that** I can revisit it later and track how my thinking has evolved over time

## Acceptance Criteria

- **Given** I am viewing an opposing-view post
  **When** I tap the Save action
  **Then** the post is added to my private "Changed My Mind" collection and a confirmation toast appears

- **Given** I navigate to my Saved Posts
  **When** I filter by "Changed My Mind"
  **Then** I see all opposing-view posts I have saved, in chronological order

## Notes
This is a personal, private collection. No notification is sent to the post's author. The save action must not imply agreement or public endorsement.
