---
id: US-373
title: "Discovery Respects Muted Keywords"
slug: discovery-respects-muted-keywords
personas: [P-005]
epic: "Discovery Engine"
priority: must-have
complexity: medium
tags: [discovery, safety, muting]
---

# US-373: Discovery Respects Muted Keywords

## User Story

**As a** Debate Seeker
**I want to** have my muted keyword list applied to discovery items as well as regular feed posts
**So that** content containing those keywords is filtered out regardless of how it was surfaced

## Acceptance Criteria

- **Given** I have muted the keyword "cryptocurrency"
  **When** the discovery engine selects items for my feed
  **Then** any discovery item whose text or tags contain "cryptocurrency" is excluded before being rendered

- **Given** I add a new keyword to my mute list
  **When** the next feed refresh occurs
  **Then** discovery items matching the new keyword are excluded from that refresh onward

## Notes
Keyword matching is case-insensitive and applies to the post body, title, and channel tags of discovery items.
