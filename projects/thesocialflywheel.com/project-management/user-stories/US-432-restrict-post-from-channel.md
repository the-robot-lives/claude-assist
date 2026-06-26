---
id: US-432
title: "Exclude a post from a specific channel"
slug: restrict-post-from-channel
personas: [P-009]
epic: "Posting & Content Creation"
priority: could-have
complexity: medium
tags: [channels, exclusion, audience, visibility]
---

# US-432: Exclude a Post from a Specific Channel

## User Story

**As a** Creator
**I want to** prevent my post from appearing in a particular interest channel
**So that** I can share content broadly while keeping it out of communities where it would be unwelcome

## Acceptance Criteria

- **Given** my post is tagged with multiple interests
  **When** I add a channel exclusion for one of those interests
  **Then** the post propagates via the remaining interest tags but is filtered out of the excluded channel's feed

- **Given** a channel exclusion is set
  **When** the propagation engine runs
  **Then** members who only follow the excluded channel do not receive the post

## Notes
Exclusions are additive; a user can exclude multiple channels from a single post.
