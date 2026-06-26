---
id: US-849
title: "People Suggestions Based on Mutual Connections"
slug: people-suggestions-based-on-mutuals
personas: [P-003]
epic: "Search & Find"
priority: should-have
complexity: medium
tags: [search, people, suggestions, mutuals, discovery]
---

# US-849: People Suggestions Based on Mutual Connections

## User Story

**As a** social connector
**I want to** see people suggestions based on mutual connections when my search has few exact matches
**So that** I discover new connections organically from search

## Acceptance Criteria

- **Given** my people search returns fewer than 5 exact results
  **When** the results panel renders
  **Then** a "You might also know" section appears with up to 3 friend-of-friend suggestions

- **Given** a suggestion appears
  **When** I view the suggestion card
  **Then** it shows the mutual connection who links us (e.g., "Mutual with @alex")

## Notes
Suggestions respect blocks and visibility; blocked users never appear as suggestions.
