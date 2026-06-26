---
id: US-865
title: "4.5:1 Minimum Color Contrast for Text"
slug: color-contrast-minimum
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: low
tags: [color-contrast, wcag-2.2, design-system]
---

# US-865: 4.5:1 Minimum Color Contrast for Text

## User Story

**As a** user with low vision
**I want to** have all body text and UI labels meet at least 4.5:1 contrast ratio
**So that** I can read the interface without straining

## Acceptance Criteria

- **Given** the default theme
  **When** I run an automated contrast check on any text element
  **Then** all text/background pairs return a contrast ratio of at least 4.5:1

- **Given** large text (18pt or 14pt bold)
  **When** contrast is measured
  **Then** the ratio is at least 3:1 per WCAG 1.4.3

- **Given** a design token change is proposed
  **When** the design system CI runs
  **Then** a contrast-check step blocks the merge if any token pair falls below threshold

## Notes

Integrate axe-core or the Deque contrast API in the CI pipeline. Surface failures as inline PR annotations pointing to the specific token pair that failed.
