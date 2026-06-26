---
id: US-887
title: "Color Not the Sole Visual Indicator"
slug: color-not-sole-indicator
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: medium
tags: [color-independence, wcag-2.2, design-system]
---

# US-887: Color Not the Sole Visual Indicator

## User Story

**As a** color-blind user
**I want to** status, error, and relationship indicators to use shape or text in addition to color
**So that** I can distinguish them without relying on color perception

## Acceptance Criteria

- **Given** a degree badge is rendered on a post card
  **When** I view it without color perception
  **Then** the badge includes a numeric label ("2nd") or text alongside any color coding, not color alone

- **Given** a form field is in an error state
  **When** it is rendered
  **Then** it shows both a border change and an error icon with text label — not a red border alone

- **Given** online/offline presence indicators are displayed
  **When** rendered
  **Then** they show a text label or distinct shape (filled circle vs ring) in addition to a color dot

## Notes
Conduct a full audit of the design token set to identify any color-only differentiators before launch. Include a color-blindness simulation step in the design review checklist.
