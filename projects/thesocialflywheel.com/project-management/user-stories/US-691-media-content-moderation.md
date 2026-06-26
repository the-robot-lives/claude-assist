---
id: US-691
title: "Media Content Moderation"
slug: media-content-moderation
personas: [P-007]
epic: "Moderation & Reporting"
priority: must-have
complexity: high
tags: [moderation, media, images, video]
---

# US-691: Media Content Moderation

## User Story

**As a** channel moderator
**I want to** have images and short videos scanned automatically before they display to the community
**So that** CSAM, graphic violence, and other prohibited visual content is caught before it causes harm

## Acceptance Criteria

- **Given** a member uploads an image or video to a channel post
  **When** the upload is processed
  **Then** the media is held and scanned by the platform's content safety service before the post appears in any member's feed; the uploader sees "Processing…" during this window

- **Given** the scan returns a high-confidence violation flag (CSAM, graphic violence)
  **When** the classification completes
  **Then** the media is permanently blocked from display, the post is withheld, the case is auto-created in the platform T&S queue, and the uploader is notified that their content was removed

- **Given** the scan returns a lower-confidence flag (possible adult content)
  **When** the classification completes
  **Then** the post is held in the channel mod queue with the scan result label and the uploader sees "Pending review" on their post

## Notes
CSAM detections must trigger immediate escalation to NCMEC-compliant reporting workflows regardless of channel-level settings.
