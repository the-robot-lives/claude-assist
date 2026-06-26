---
id: US-424
title: "Attach multiple images to a single post"
slug: multiple-image-attachment
personas: [P-009]
epic: "Posting & Content Creation"
priority: should-have
complexity: medium
tags: [media, images, gallery, attachment]
---

# US-424: Attach Multiple Images to a Single Post

## User Story

**As a** Creator
**I want to** attach up to ten images to a single post as a gallery
**So that** I can share photo sets or visual sequences in one cohesive post

## Acceptance Criteria

- **Given** I am composing a post
  **When** I add multiple images (up to 10)
  **Then** a scrollable gallery preview is shown in the composer

- **Given** a multi-image post is published
  **When** recipients view it
  **Then** the gallery is rendered as a swipeable carousel

## Notes
Each image must have its own alt text field (US-416). Gallery order is user-defined (US-446).
