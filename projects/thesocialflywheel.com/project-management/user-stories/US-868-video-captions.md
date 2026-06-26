---
id: US-868
title: "Captions for Posted Videos"
slug: video-captions
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: high
tags: [captions, video, wcag-2.2]
---

# US-868: Captions for Posted Videos

## User Story

**As a** deaf or hard-of-hearing user
**I want to** have all videos posted in channels display synchronized captions
**So that** I can understand audio content without hearing it

## Acceptance Criteria

- **Given** a video is posted in a channel
  **When** it plays
  **Then** captions are visible by default and can be toggled on/off

- **Given** a creator uploads a video without a caption file
  **When** the upload completes
  **Then** the platform generates auto-captions and flags them for creator review

- **Given** auto-captions are pending review
  **When** a viewer watches the video
  **Then** a notice reads "Captions are auto-generated and may contain errors."

## Notes
Auto-caption generation should be handled asynchronously via a background job; caption files must be stored in WebVTT format and served via the HTML5 `<track>` element with `kind="captions"`.
