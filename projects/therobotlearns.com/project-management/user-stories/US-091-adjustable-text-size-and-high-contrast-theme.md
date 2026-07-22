---
id: US-091
title: "Adjustable text size and high-contrast theme"
slug: adjustable-text-size-and-high-contrast-theme
personas: [P-007]
epic: "Accessibility & i18n"
priority: must-have
complexity: medium
tags: [accessibility, theming, ui]
---

# US-091: Adjustable Text Size and High-Contrast Theme

## User Story

**As a** senior developer using assistive technology in the browser
**I want to** adjust text size and switch to a high-contrast theme in the quiz SPA
**So that** the interface remains usable regardless of my visual needs

## Acceptance Criteria

- **Given** the quiz SPA settings panel
  **When** the user increases or decreases text size
  **Then** all quiz content and controls scale accordingly without clipping text or breaking layout

- **Given** the user enables the high-contrast theme
  **When** it is applied
  **Then** all text/background combinations meet WCAG AA contrast requirements

- **Given** the user sets a text size or theme preference
  **When** they reload or reopen the SPA
  **Then** the preference persists across sessions (stored locally)

## Notes
Should compose cleanly with reduced-motion and WCAG AA requirements from US-089.
