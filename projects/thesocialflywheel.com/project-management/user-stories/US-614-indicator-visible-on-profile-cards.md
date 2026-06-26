---
id: US-614
title: "Indicator Visible on Profile Cards"
slug: indicator-visible-on-profile-cards
personas: [P-008]
epic: "Safety: Blocking & Exclusions"
priority: could-have
complexity: low
tags: [safety, blocking, accessibility]
---

# US-614: Indicator Visible on Profile Cards

## User Story

**As an** accessibility-first user
**I want to** have the "mutual of a blocked person" indicator available to screen readers and high-contrast themes
**So that** I can receive the same safety signal regardless of how I access the platform

## Acceptance Criteria

- **Given** the mutual-of-blocked indicator is shown on a profile card
  **When** a screen reader focuses on that card
  **Then** the reader announces the indicator text as well as the user's name

- **Given** high-contrast mode is enabled
  **When** the indicator is displayed
  **Then** it meets WCAG AA contrast ratio requirements

## Notes
Builds on US-613; this story focuses on accessibility of the indicator, not its logic.
