---
id: US-621
title: "Dislike Interest to Stop Discovery Thread"
slug: dislike-interest-to-stop-discovery-thread
personas: [P-006]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: low
tags: [safety, discovery, dislike]
---

# US-621: Dislike Interest to Stop Discovery Thread

## User Story

**As a** quiet consumer
**I want to** mark a surfaced interest as disliked to stop that thread of Discovery
**So that** the algorithm stops pulling me toward content I am not interested in without requiring a formal exclusion

## Acceptance Criteria

- **Given** a post appears in my Discovery lane
  **When** I long-press or swipe-down on it and select "Not interested in [tag]"
  **Then** future posts primarily tagged with that interest are deprioritised in Discovery

- **Given** I have disliked an interest tag
  **When** I view my Preference signals in Settings
  **Then** the disliked tag appears under "Discovery dislikes" with the date applied

## Notes
Dislike is lighter than exclusion: it reduces rather than eliminates; full exclusion is still available via US-601.
