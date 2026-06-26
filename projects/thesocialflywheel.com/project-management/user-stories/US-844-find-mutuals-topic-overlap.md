---
id: US-844
title: "Find Mutuals with Specific Topic Overlap"
slug: find-mutuals-topic-overlap
personas: [P-003]
epic: "Search & Find"
priority: should-have
complexity: medium
tags: [search, mutuals, topics, interests, overlap]
---

# US-844: Find Mutuals with Specific Topic Overlap

## User Story

**As a** social connector
**I want to** find mutual connections who are engaged with a specific topic
**So that** I can initiate conversations with moots around shared passions

## Acceptance Criteria

- **Given** I search for a topic and enable "Mutuals only"
  **When** results load
  **Then** only 1st-degree moots who follow or have posted in channels related to that topic appear

- **Given** results show mutual matches
  **When** I view a card
  **Then** the number of shared channels and followed topics is summarized (e.g., "3 shared channels")

## Notes
Topic engagement signals include: channel membership, posts, reactions, and followed interest tags.
