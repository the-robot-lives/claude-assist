---
id: US-843
title: "Search Queries Are Private"
slug: search-query-privacy
personas: [P-006]
epic: "Search & Find"
priority: must-have
complexity: medium
tags: [search, privacy, queries, security]
---

# US-843: Search Queries Are Private

## User Story

**As a** quiet consumer
**I want to** have my search queries remain private
**So that** I can explore sensitive topics or look up specific people without being exposed

## Acceptance Criteria

- **Given** I search for a user's name
  **When** the search runs
  **Then** that user receives no notification or any indication that they were searched

- **Given** I search for a sensitive topic
  **When** results appear
  **Then** no activity feed, social signal, or notification is generated that reveals my search to anyone else

## Notes
Search query data used for internal analytics must be anonymized and not attributable to individual users in any user-visible surface.
