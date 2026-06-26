---
id: US-447
title: "Blur sensitive images behind a content warning"
slug: sensitive-image-blur
personas: [P-008]
epic: "Posting & Content Creation"
priority: must-have
complexity: medium
tags: [sensitive, nsfw, blur, safety, accessibility]
---

# US-447: Blur Sensitive Images Behind a Content Warning

## User Story

**As an** Accessibility-First user
**I want to** see sensitive or NSFW images blurred by default with a click-through warning
**So that** I am not exposed to unwanted content in my feed involuntarily

## Acceptance Criteria

- **Given** a post is marked Sensitive or NSFW (US-415)
  **When** it appears in my feed
  **Then** all attached images are rendered with a heavy blur and an "Sensitive content" label overlay

- **Given** a blurred image is in my feed
  **When** I tap "Show image"
  **Then** only that specific image in that specific post is unblurred for that session

## Notes
Blur persists across feed refreshes; a per-post "Always show" toggle is a future enhancement.
