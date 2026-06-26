---
id: US-542
title: "View Shared Media Gallery in Conversation"
slug: view-shared-media-gallery
personas: [P-009]
epic: "Chat & Real-time Messaging"
priority: could-have
complexity: medium
tags: [media-gallery, images, files, chat]
---

# US-542: View Shared Media Gallery in Conversation

## User Story

**As a** Creator (P-009)
**I want to** view a gallery of all media and files shared in a conversation
**So that** I can find and download assets without scrolling through the entire chat history

## Acceptance Criteria

- **Given** I open conversation details (tap the name or "i" icon)
  **When** I select the "Media & Files" section
  **Then** I see a grid of all images and a list of all files shared in this conversation, sorted newest first

- **Given** I tap an image in the gallery
  **When** the lightbox opens
  **Then** I can swipe left and right to browse all shared images in chronological order

- **Given** I long-press a file or image in the gallery
  **When** the context menu appears
  **Then** I can download it, copy a link, or jump to the originating message in the thread

## Notes
Gallery is scoped to the current conversation only. Cross-conversation media search is handled by US-524.
