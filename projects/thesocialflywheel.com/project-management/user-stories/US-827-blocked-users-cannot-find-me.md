---
id: US-827
title: "Blocked Users Cannot Discover Me via Search"
slug: blocked-users-cannot-find-me
personas: [P-006]
epic: "Search & Find"
priority: must-have
complexity: high
tags: [search, privacy, blocks, safety]
---

# US-827: Blocked Users Cannot Discover Me via Search

## User Story

**As a** quiet consumer
**I want to** be invisible in search to users who have blocked me
**So that** my privacy and safety are protected

## Acceptance Criteria

- **Given** user B has blocked me
  **When** user B searches my username or display name
  **Then** I do not appear in any of their search results

- **Given** user B has blocked me
  **When** user B searches posts in a shared channel
  **Then** my posts in that channel are not visible to them

## Notes
This is a one-way effect: the person who issued the block sees neither the blocked user nor their content.
