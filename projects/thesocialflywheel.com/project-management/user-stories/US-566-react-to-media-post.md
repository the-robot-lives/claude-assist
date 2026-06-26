---
id: US-566
title: "React to an Image or Video Post"
slug: react-to-media-post
personas: [P-006, P-009]
epic: "Reactions & Engagement"
priority: should-have
complexity: medium
tags: [reactions, media, engagement]
---

# US-566: React to an Image or Video Post

## User Story

**As a** Quiet Consumer
**I want to** react to image or video posts the same way I react to text posts
**So that** my engagement is consistent across all content types

## Acceptance Criteria

- **Given** I am viewing an image post
  **When** I tap the reaction button
  **Then** the standard emoji picker appears and my reaction is applied to the post entity

- **Given** I am watching a video post
  **When** I double-tap the video
  **Then** a heart reaction is applied instantly as a quick-react shortcut with a brief animation overlay

## Notes
Reactions attach to the post entity, not to a specific frame or timestamp. Per-timestamp reactions are out of scope for v1.
