---
id: US-597
title: "Mute Reactions from a Specific User on My Posts"
slug: mute-reactions-specific-user
personas: [P-009]
epic: "Reactions & Engagement"
priority: should-have
complexity: medium
tags: [anti-harassment, reactions, mute, creator]
---

# US-597: Mute Reactions from a Specific User on My Posts

## User Story

**As a** Creator
**I want to** mute reactions from a specific user on my posts
**So that** I can prevent targeted reaction-spamming without fully blocking them

## Acceptance Criteria

- **Given** a user is repeatedly spamming reactions on my posts
  **When** I long-press their name in the reactor list and select "Mute reactions"
  **Then** their future reactions on my posts are silently discarded server-side

- **Given** I have muted a user's reactions
  **When** they react to my post
  **Then** they see their reaction applied normally (no indication they are muted) but I do not see it and my count does not increment

## Notes
Muted-reactions list is manageable in Settings → Privacy → Muted Users. Does not prevent the user from viewing or replying to my posts.
