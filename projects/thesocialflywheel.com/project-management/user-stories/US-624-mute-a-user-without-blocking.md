---
id: US-624
title: "Mute a User Without Blocking"
slug: mute-a-user-without-blocking
personas: [P-006]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: low
tags: [safety, mute]
---

# US-624: Mute a User Without Blocking

## User Story

**As a** quiet consumer
**I want to** mute another user so their posts disappear from my feeds
**So that** I can reduce noise without the permanence or social signal of a block

## Acceptance Criteria

- **Given** I select "Mute [username]" from a profile or post menu
  **When** I confirm the action
  **Then** that user's posts are hidden from all my lanes without blocking them

- **Given** a user is muted
  **When** they post in a channel I follow
  **Then** their post is not shown to me but is visible to other members

## Notes
Muted users are unaware they have been muted. Mute vs block distinction is surfaced in US-626.
