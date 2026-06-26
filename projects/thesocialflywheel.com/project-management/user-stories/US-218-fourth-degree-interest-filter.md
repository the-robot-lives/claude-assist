---
id: US-218
title: "Fourth-Degree Interest Filter"
slug: fourth-degree-interest-filter
personas: [P-004]
epic: "Mutuals Graph & Degrees"
priority: should-have
complexity: medium
tags: [feed, degrees, interests]
---

# US-218: Fourth-Degree Interest Filter

## User Story

**As a** Cautious Newcomer (P-004)
**I want to** see only highly relevant posts from 4th-degree mutuals, filtered by my interests
**So that** the most distant reachable users contribute only truly matching content to my feed

## Acceptance Criteria

- **Given** a 4th-degree mutual posts content matching my subscribed interests
  **When** my feed is compiled
  **Then** the post may appear at the lowest priority tier, below 3rd-degree content

- **Given** I have not subscribed to any interests
  **When** my feed is built
  **Then** no 2nd–4th degree content appears (interest subscriptions are a prerequisite for outer-degree visibility)

## Notes
4th-degree is the hard boundary of the mutuals web. No content beyond 4th degree reaches the main feed under any circumstance (see US-219).
