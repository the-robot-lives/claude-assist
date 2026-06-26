---
id: US-189
title: "Discover Channels via Interest Adjacency"
slug: discover-channels-via-interest-adjacency
personas: [P-001]
epic: "Interest Channels"
priority: should-have
complexity: high
tags: [channels, discovery, interest-adjacency, network, algorithm]
---

# US-189: Discover Channels via Interest Adjacency

## User Story

**As a** Bridge-Builder
**I want to** discover channels whose interest tags are adjacent to (not exactly matching) my current interests
**So that** I can expand my perspective by exploring related communities I haven't considered yet

## Acceptance Criteria

- **Given** I am on the Discover tab
  **When** a "Related Interests" section is displayed
  **Then** it shows channels whose tags are one semantic step away from my primary interests (e.g., someone interested in "Jazz" also sees "Music History" and "Blues" channel suggestions)

- **Given** I tap "Why suggested?" on an adjacent-interest channel card
  **When** the tooltip opens
  **Then** it names the specific interest tag that links my profile to this channel suggestion

## Notes
Adjacent interest mapping is maintained by the platform (not user-configured). At minimum, adjacency should be first-order (directly connected tags in the interest graph). This feature depends on the interest tag taxonomy being a graph, not a flat list.
