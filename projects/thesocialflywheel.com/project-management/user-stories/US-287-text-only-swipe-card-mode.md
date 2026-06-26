---
id: US-287
title: "Text-Only Swipe Card Mode"
slug: text-only-swipe-card-mode
personas: [P-008]
epic: "Swipe-to-Match"
priority: should-have
complexity: low
tags: [low-bandwidth, accessibility, text-only, data-saver]
---

# US-287: Text-Only Swipe Card Mode

## User Story

**As an** Accessibility-First user (P-008)
**I want to** enable a text-only mode for swipe cards that removes all images
**So that** the interface is faster and easier to navigate for users who prefer or require non-visual content

## Acceptance Criteria

- **Given** I have enabled Text-Only mode in my accessibility settings
  **When** a swipe card loads
  **Then** avatar images are replaced with a colored initial monogram and no other images are fetched

- **Given** text-only mode is active
  **When** I navigate between cards
  **Then** all card content loads without any image network requests and the layout remains consistent
