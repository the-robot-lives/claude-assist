---
id: US-814
title: "Search Respects Channel Visibility Rules"
slug: search-respects-visibility-rules
personas: [P-006]
epic: "Search & Find"
priority: must-have
complexity: high
tags: [search, visibility, private-channels, access-control]
---

# US-814: Search Respects Channel Visibility Rules

## User Story

**As a** quiet consumer
**I want to** have search only return content I am permitted to view
**So that** private or restricted channels don't leak content through search

## Acceptance Criteria

- **Given** a channel is set to members-only
  **When** I search for a post in that channel and I am not a member
  **Then** no posts from that channel appear in results

- **Given** I join a previously members-only channel
  **When** I search again
  **Then** posts from that channel now appear in results

## Notes
Access checks are enforced server-side on every query; cached results must be invalidated on membership change.
