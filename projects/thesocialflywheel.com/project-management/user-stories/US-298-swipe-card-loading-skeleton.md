---
id: US-298
title: "Swipe Card Loading Skeleton"
slug: swipe-card-loading-skeleton
personas: [P-008]
epic: "Swipe-to-Match"
priority: should-have
complexity: low
tags: [loading, skeleton, accessibility, swipe-ui, performance]
---

# US-298: Swipe Card Loading Skeleton

## User Story

**As an** Accessibility-First user (P-008)
**I want to** see a loading skeleton while the next swipe card is being fetched
**So that** I know the app is working and my place in the UI is stable

## Acceptance Criteria

- **Given** the next card is loading after I swipe
  **When** the fetch takes more than 200ms
  **Then** a skeleton card matching the card's layout is shown in place of the real card

- **Given** the skeleton is visible
  **When** a screen reader encounters it
  **Then** it announces "Loading next candidate" via an aria-live region rather than reading out empty placeholder shapes
