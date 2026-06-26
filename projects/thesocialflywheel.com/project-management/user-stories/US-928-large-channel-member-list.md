---
id: US-928
title: "Paginated Member List for Large Channels"
slug: large-channel-member-list
personas: [P-007]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: medium
tags: [channels, members, pagination, moderation, scale]
---

# US-928: Paginated Member List for Large Channels

## User Story

**As a** channel moderator managing a community with tens of thousands of members
**I want to** browse and search the member list in paginated chunks
**So that** the moderation panel loads quickly and I can act on members without waiting for a full list render

## Acceptance Criteria

- **Given** a channel has more than 1,000 members
  **When** I open the member management panel
  **Then** members are shown in pages of 50 with cursor-based pagination, loading in under 1 second per page

- **Given** I search for a member by username in a large channel
  **When** I type at least 2 characters
  **Then** matching results appear within 500 ms using a server-side prefix search

## Notes
Use DB index on `(channel_id, username)` for member search. Never load the full member list in the browser. Cursor pagination preferred over offset for large tables.
