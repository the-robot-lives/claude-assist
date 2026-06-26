---
id: US-280
title: "Swipe Card Post Preview"
slug: swipe-card-post-preview
personas: [P-002]
epic: "Swipe-to-Match"
priority: should-have
complexity: medium
tags: [card-layout, post-preview, content-evaluation]
---

# US-280: Swipe Card Post Preview

## User Story

**As a** Niche Enthusiast (P-002)
**I want to** see a sample of a candidate's recent posts on their swipe card
**So that** I can assess whether their content style and depth match what I want in a mutual

## Acceptance Criteria

- **Given** a candidate has recent public posts in a shared interest channel
  **When** their swipe card is shown
  **Then** up to two post excerpts (max 140 chars each) are displayed in a scrollable preview area on the card

- **Given** a candidate has no public posts
  **When** their card is shown
  **Then** a "No public posts yet" placeholder appears in the preview area
