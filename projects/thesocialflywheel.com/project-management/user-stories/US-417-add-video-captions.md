---
id: US-417
title: "Add captions to an attached video"
slug: add-video-captions
personas: [P-008]
epic: "Posting & Content Creation"
priority: should-have
complexity: high
tags: [accessibility, captions, video, a11y]
---

# US-417: Add Captions to an Attached Video

## User Story

**As an** Accessibility-First user
**I want to** upload or auto-generate captions for my video post
**So that** deaf and hard-of-hearing users can fully engage with my video content

## Acceptance Criteria

- **Given** I have attached a video
  **When** I tap "Add captions" and upload a .vtt or .srt file
  **Then** the captions are burned into the video player for all viewers

- **Given** no caption file is uploaded
  **When** I tap "Auto-generate captions"
  **Then** the system generates captions server-side and I can review/edit them before publishing

## Notes
Auto-generation accuracy depends on audio quality. Manual upload always preferred for accuracy.
