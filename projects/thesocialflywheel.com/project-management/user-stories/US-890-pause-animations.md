---
id: US-890
title: "Pause, Stop, or Hide Auto-Playing Content"
slug: pause-animations
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: medium
tags: [animation-control, wcag-2.2, reduced-motion]
---

# US-890: Pause, Stop, or Hide Auto-Playing Content

## User Story

**As a** user with vestibular or attention sensitivities
**I want to** controls to pause, stop, or hide any content that moves or auto-plays for more than three seconds
**So that** I can use the platform without distraction or discomfort

## Acceptance Criteria

- **Given** an auto-playing GIF or looping video is in the feed
  **When** I tab to or click a visible "Pause" button adjacent to the element
  **Then** all motion in that element stops immediately and the button label changes to "Play"

- **Given** my system's reduced-motion preference is enabled
  **When** auto-playing media is encountered in the feed
  **Then** it is paused by default and a "Play" button is shown rather than auto-starting

- **Given** a live activity ticker scrolls automatically
  **When** it is visible in the UI
  **Then** a keyboard-accessible "Pause" button is present within the ticker region

## Notes
Covers WCAG 2.2.2 Pause, Stop, Hide. Include auto-playing content detection in the pre-launch accessibility audit checklist. GIFs should be treated identically to videos for this control.
