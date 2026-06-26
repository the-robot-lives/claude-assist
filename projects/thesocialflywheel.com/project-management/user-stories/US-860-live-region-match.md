---
id: US-860
title: "Live Region for New Moot Match"
slug: live-region-match
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: should-have
complexity: low
tags: [live-regions, screen-reader, swipe, wcag-2.2]
---

# US-860: Live Region for New Moot Match

## User Story

**As a** screen-reader user
**I want to** receive a polite announcement when I match with someone in Swipe-to-Match
**So that** I am aware of the match without missing it visually

## Acceptance Criteria

- **Given** I accept a swipe card
  **When** a mutual match forms
  **Then** a polite live region announces "You matched with [Name]! View their profile or keep swiping."

- **Given** the match celebration animation plays
  **When** the announcement fires
  **Then** it does not interrupt any in-progress screen-reader speech

- **Given** I am in reduced-motion mode
  **When** a match occurs
  **Then** the animation is suppressed but the live-region announcement still fires

## Notes

Fire the live region update only after the animation completes (or immediately if reduced-motion is active) to synchronize audio with visual feedback.
