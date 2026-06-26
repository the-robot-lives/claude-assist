---
id: US-434
title: "Attach a GIF or animated image to a post"
slug: attach-gif
personas: [P-009]
epic: "Posting & Content Creation"
priority: should-have
complexity: medium
tags: [media, gif, animation, attachment]
---

# US-434: Attach a GIF or Animated Image to a Post

## User Story

**As a** Creator
**I want to** attach a GIF or animated WebP to my post
**So that** I can add expressive animated reactions or illustrative loops to my content

## Acceptance Criteria

- **Given** I tap the media picker in the composer
  **When** I select a .gif or animated .webp file
  **Then** the animation plays in the composer preview

- **Given** a GIF post is published
  **When** recipients view the post
  **Then** the GIF auto-plays on loop with an option to pause

## Notes
GIFs respect the "Reduce Motion" accessibility setting; they pause by default for users with that preference enabled.
