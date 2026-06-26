---
id: US-353
title: "Like Discovery Item Tunes Future Content"
slug: like-discovery-item-tunes-future-content
personas: [P-002]
epic: "Discovery Engine"
priority: must-have
complexity: medium
tags: [discovery, feedback, tuning]
---

# US-353: Like Discovery Item Tunes Future Content

## User Story

**As a** Niche Enthusiast
**I want to** like a discovery item to signal positive interest
**So that** the engine surfaces more content from that adjacent topic in future sessions

## Acceptance Criteria

- **Given** a discovery item is visible in my feed
  **When** I tap the like button on the item
  **Then** the engine increases the weight of that adjacent topic in my discovery profile

- **Given** I have liked several discovery items in a topic cluster
  **When** the next feed session loads
  **Then** I see a higher proportion of content from that topic cluster within the same rotation period

## Notes
Likes on discovery items are distinct from likes on regular posts and feed into the tuning model, not the social engagement graph.
