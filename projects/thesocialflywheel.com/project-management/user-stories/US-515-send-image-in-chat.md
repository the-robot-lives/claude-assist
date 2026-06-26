---
id: US-515
title: "Send Image in Chat"
slug: send-image-in-chat
personas: [P-009]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: medium
tags: [media, images, chat]
---

# US-515: Send Image in Chat

## User Story

**As a** Creator (P-009)
**I want to** attach and send images directly within a DM or channel chat
**So that** I can share visual content without linking to an external host

## Acceptance Criteria

- **Given** I am composing a message
  **When** I tap the attachment icon and select one or more images from my device
  **Then** thumbnail previews appear in the compose area and sending delivers the images inline in the thread

- **Given** an image is sent in the chat
  **When** a recipient taps the thumbnail
  **Then** it opens in a full-screen lightbox with pinch-to-zoom and a download option

- **Given** I attempt to send an image larger than 25 MB
  **When** I select it
  **Then** an error message informs me of the size limit and the image is not attached

## Notes
Accepted formats: JPEG, PNG, GIF, WebP. Images are stored in platform CDN; originals are accessible to sender and recipients for 90 days.
