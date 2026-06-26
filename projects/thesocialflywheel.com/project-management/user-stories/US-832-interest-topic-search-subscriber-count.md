---
id: US-832
title: "Interest Topic Search Shows Subscriber Count"
slug: interest-topic-search-subscriber-count
personas: [P-002]
epic: "Search & Find"
priority: could-have
complexity: low
tags: [search, interests, topics, metadata]
---

# US-832: Interest Topic Search Shows Subscriber Count

## User Story

**As a** niche enthusiast
**I want to** see subscriber count in interest topic search results
**So that** I can gauge community size before following a topic

## Acceptance Criteria

- **Given** I search for an interest topic
  **When** results appear
  **Then** each topic card shows a subscriber count and number of active channels using that topic

- **Given** I click "Follow" on a topic in search results
  **When** the action completes
  **Then** the subscriber count increments and the button state changes to "Following"

## Notes
The Follow action must be undoable from the same card without leaving search results.
