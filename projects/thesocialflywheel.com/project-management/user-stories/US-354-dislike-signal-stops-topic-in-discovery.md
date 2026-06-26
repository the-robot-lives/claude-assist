---
id: US-354
title: "Dislike Signal Stops Topic in Discovery"
slug: dislike-signal-stops-topic-in-discovery
personas: [P-005]
epic: "Discovery Engine"
priority: must-have
complexity: medium
tags: [discovery, feedback, tuning]
---

# US-354: Dislike Signal Stops Topic in Discovery

## User Story

**As a** Debate Seeker
**I want to** dislike a discovery item to signal that I do not want that topic surfaced
**So that** the engine stops serving that specific adjacent topic until I reset my preferences

## Acceptance Criteria

- **Given** a discovery item is visible in my feed
  **When** I tap the dislike button on the item
  **Then** the engine suppresses that topic from discovery for the remainder of the current rotation period

- **Given** I have disliked a topic
  **When** the monthly rotation resets
  **Then** the topic remains suppressed unless I explicitly re-enable it

## Notes
Dislike applies to the topic cluster, not just the individual post.
