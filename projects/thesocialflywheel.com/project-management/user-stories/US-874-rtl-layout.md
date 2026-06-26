---
id: US-874
title: "Right-to-Left Layout Support"
slug: rtl-layout
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: high
tags: [rtl, i18n, layout, wcag-2.2]
---

# US-874: Right-to-Left Layout Support

## User Story

**As a** user whose language reads right-to-left
**I want to** have the entire app layout mirror horizontally
**So that** navigation, sidebars, and content flow match my reading direction

## Acceptance Criteria

- **Given** my account language is set to Arabic or Hebrew
  **When** I open the app
  **Then** the HTML `dir` attribute is `"rtl"` and the channel sidebar appears on the right side

- **Given** RTL mode is active
  **When** I view the feed
  **Then** post cards, avatars, and metadata align to the right

- **Given** RTL mode is active
  **When** I open a modal
  **Then** the close button appears on the left side (visually) of the modal header

## Notes
Use CSS logical properties (`inline-start`/`end`) throughout; avoid left/right physical properties. Icon assets that imply direction (e.g., arrows, back buttons) must be mirrored via `transform: scaleX(-1)` or separate RTL-specific assets.
