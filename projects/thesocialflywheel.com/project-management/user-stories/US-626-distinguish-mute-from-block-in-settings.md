---
id: US-626
title: "Distinguish Mute from Block in Settings"
slug: distinguish-mute-from-block-in-settings
personas: [P-008]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: low
tags: [safety, mute, accessibility]
---

# US-626: Distinguish Mute from Block in Settings

## User Story

**As an** accessibility-first user
**I want to** clearly understand the difference between muting and blocking within the Safety settings UI
**So that** I choose the right tool for my situation without confusion

## Acceptance Criteria

- **Given** I open Settings > Safety
  **When** the page loads
  **Then** "Muted Users" and "Blocked Users" are listed as separate, clearly labelled sections with a one-sentence explanation of each

- **Given** I hover or focus on either section label
  **When** a tooltip or expandable description activates
  **Then** it explains: mute hides their content from you only; block is mutual and may cascade

## Notes
Plain language is critical; avoid jargon. Test with screen-reader and cognitive-load review.
