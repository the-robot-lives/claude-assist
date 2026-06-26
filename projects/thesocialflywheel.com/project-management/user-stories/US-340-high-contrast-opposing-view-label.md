---
id: US-340
title: "High-Contrast Label for Opposing-View Context"
slug: high-contrast-opposing-view-label
personas: [P-008]
epic: "Opposing-Views Lane"
priority: must-have
complexity: low
tags: [opposing-views, accessibility, contrast, a11y, label]
---

# US-340: High-Contrast Label for Opposing-View Context

## User Story

**As an** accessibility-first user
**I want to** see the opposing-view context label in high-contrast colors that meet WCAG AA standards
**So that** I can reliably distinguish opposing-view posts from regular posts without straining my vision

## Acceptance Criteria

- **Given** I view an opposing-view post
  **When** the label "Opposing view on [Interest]" is rendered
  **Then** the label text achieves a minimum 4.5:1 contrast ratio against its background in both light and dark themes

- **Given** I enable system-level high-contrast mode
  **When** the label renders
  **Then** it adapts to the high-contrast color palette and remains legible

## Notes
Use a color token from the design system's semantic "informational" or "opposing" palette. Do not rely solely on color to distinguish the label — use an icon or shape indicator as well.
