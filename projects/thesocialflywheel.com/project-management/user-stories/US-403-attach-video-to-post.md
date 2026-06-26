---
id: US-403
title: "Attach a video to a post"
slug: attach-video-to-post
personas: [P-009]
epic: "Posting & Content Creation"
priority: must-have
complexity: high
tags: [media, video, attachment]
---

# US-403: Attach a Video to a Post

## User Story

**As a** Creator
**I want to** attach a short video clip to my post
**So that** I can share dynamic content beyond static images

## Acceptance Criteria

- **Given** I am composing a post
  **When** I select a video file under 500 MB
  **Then** the video is transcoded server-side and a preview thumbnail is shown before I publish

- **Given** a video is uploading
  **When** upload completes
  **Then** the post becomes publishable and an upload-complete notification is shown

## Notes
Transcoding may take seconds to minutes; composer should remain usable during background upload.
