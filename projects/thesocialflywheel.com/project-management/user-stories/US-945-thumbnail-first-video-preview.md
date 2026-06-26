---
id: US-945
title: "Thumbnail-First Video Preview Before Stream Loads"
slug: thumbnail-first-video-preview
personas: [P-009]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: low
tags: [video, thumbnail, preview, perceived-performance, creator]
---

# US-945: Thumbnail-First Video Preview Before Stream Loads

## User Story

**As a** creator who posts video content to channels
**I want to** have a static thumbnail displayed instantly in my video posts
**So that** viewers see meaningful content preview before the video stream begins buffering

## Acceptance Criteria

- **Given** a video post is rendered in the feed
  **When** the post enters the viewport
  **Then** a static thumbnail image is displayed immediately without waiting for the video manifest to load

- **Given** the user taps the play button
  **When** the video starts loading
  **Then** the thumbnail remains visible until the first video frame is ready, then cross-fades out

## Notes
Generate thumbnail at 00:00:01 on upload. Store as WebP. Embed thumbnail URL in feed post API payload so no extra request is needed. Require explicit play tap to initiate stream; do not autoplay.
