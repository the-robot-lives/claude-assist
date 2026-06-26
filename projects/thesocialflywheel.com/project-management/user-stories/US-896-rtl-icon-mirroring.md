---
id: US-896
title: "RTL-Aware Icon Mirroring"
slug: rtl-icon-mirroring
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: should-have
complexity: low
tags: [rtl, icons, i18n]
---

# US-896: RTL-Aware Icon Mirroring

## User Story

**As an** RTL-language user
**I want to** directional icons such as arrows, back buttons, and chevrons to flip horizontally
**So that** they correctly indicate direction within my right-to-left reading context

## Acceptance Criteria

- **Given** RTL mode is active
  **When** I view a "Back" button with a left-pointing arrow
  **Then** the arrow points right, correctly indicating the back direction in RTL context

- **Given** RTL mode is active
  **When** I see the channel sidebar toggle chevron
  **Then** it points in the correct direction for opening or closing the sidebar in RTL layout

- **Given** a non-directional icon (heart, star, notification bell) is rendered
  **When** RTL mode is active
  **Then** it is not mirrored, as mirroring would be visually incorrect for symmetrical icons

## Notes
Implement selective mirroring using CSS `transform: scaleX(-1)` applied only to icons tagged as directional in the icon library. Maintain a documented list of directional vs. non-directional icons to prevent incorrect mirroring.
