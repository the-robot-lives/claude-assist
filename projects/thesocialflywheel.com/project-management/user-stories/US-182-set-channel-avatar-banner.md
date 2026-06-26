---
id: US-182
title: "Set Channel Avatar and Banner"
slug: set-channel-avatar-banner
personas: [P-007]
epic: "Interest Channels"
priority: should-have
complexity: low
tags: [channels, avatar, banner, branding, settings]
---

# US-182: Set Channel Avatar and Banner

## User Story

**As a** Channel Moderator
**I want to** upload a custom avatar and banner image for my channel
**So that** the channel has a distinct visual identity that reflects its community and makes it recognizable in the directory

## Acceptance Criteria

- **Given** I am in channel settings
  **When** I upload an image as the channel avatar (min 200×200px, max 5MB)
  **Then** it replaces the default generated avatar and appears in the channel directory card, member sidebar, and channel info page

- **Given** I upload a banner image (min 1200×300px, max 10MB)
  **When** the upload completes
  **Then** the banner appears at the top of the channel info page and the channel's main feed header

## Notes
Supported formats: JPEG, PNG, WebP. Images should be processed server-side to strip EXIF metadata. Moderately inappropriate imagery should be flagged via content moderation pipeline; overtly inappropriate imagery auto-rejected.
