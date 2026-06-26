---
id: US-897
title: "High Contrast Dark Mode Variant"
slug: high-contrast-dark
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: should-have
complexity: medium
tags: [high-contrast, dark-mode, color, accessibility]
---

# US-897: High Contrast Dark Mode Variant

## User Story

**As a** low-vision user who prefers a dark background
**I want to** a high-contrast dark mode that maintains 7:1 text contrast
**So that** I can reduce screen glare while retaining full readability

## Acceptance Criteria

- **Given** I enable "High Contrast Dark" in Appearance settings
  **When** the theme applies
  **Then** the background is near-black (#0a0a0a or equivalent) and all body text achieves ≥7:1 contrast ratio

- **Given** high-contrast dark mode is active
  **When** interactive components (buttons, inputs, links) render
  **Then** each has a visible border of at least 2px in a high-contrast color against the dark background

- **Given** the OS dark-mode system preference is enabled AND the user has explicitly selected high-contrast in app settings
  **When** these preferences conflict
  **Then** the user's explicit in-app setting takes precedence over the OS-level preference

## Notes
Implement as a separate CSS custom property theme layer rather than overriding the standard dark mode. Use the `prefers-color-scheme: dark` media query as a default starting point, then layer high-contrast overrides on top.
