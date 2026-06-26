---
id: US-590
title: "React to a Video Post While Watching"
slug: react-to-video-post
personas: [P-006]
epic: "Reactions & Engagement"
priority: should-have
complexity: medium
tags: [media, video, reactions]
---

# US-590: React to a Video Post While Watching

## User Story

**As a** Quiet Consumer
**I want to** react to a video post while watching it
**So that** I can express a reaction in the moment without stopping playback

## Acceptance Criteria

- **Given** a video is playing
  **When** I double-tap the video area
  **Then** a heart reaction is added and a brief animation overlays the video without pausing playback

- **Given** I want a different reaction
  **When** I long-press the video area
  **Then** the full reaction picker appears in an overlay and playback pauses until I make a selection

## Notes
Reactions attach to the post entity, not to a per-frame timestamp. Timestamp reactions are explicitly out of scope for v1.
