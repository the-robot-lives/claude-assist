---
id: US-864
title: "High Contrast Theme"
slug: high-contrast-theme
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: medium
tags: [high-contrast, color, wcag-2.2]
---

# US-864: High Contrast Theme

## User Story

**As a** low-vision user
**I want to** have a dedicated high-contrast theme with distinct borders and pure black/white backgrounds
**So that** all UI elements are clearly distinguishable

## Acceptance Criteria

- **Given** I enable "High Contrast" in settings
  **When** the theme applies
  **Then** all text achieves at least 7:1 contrast ratio against its background

- **Given** high-contrast mode is active
  **When** I view interactive components (buttons, links, inputs)
  **Then** each has a visible 2px solid border distinct from the background

- **Given** the OS forced-colors (Windows High Contrast) mode is active
  **When** I open the app
  **Then** the UI respects the forced-color palette without showing invisible text

## Notes

Use CSS forced-colors media query and CSS custom properties to switch palettes. Test with both Windows High Contrast Black and High Contrast White system themes.
