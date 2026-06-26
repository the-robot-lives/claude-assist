---
id: US-126
title: "Meet color contrast compliance on profiles"
slug: profile-color-contrast
personas: [P-008]
epic: "Profile & Identity"
priority: must-have
complexity: low
tags: [profile, accessibility, a11y, contrast]
---

# US-126: Meet Color Contrast Compliance On Profiles

## User Story

**As an** accessibility-first user
**I want to** read profile text and controls with sufficient contrast
**So that** I can use the profile with low vision or in bright conditions

## Acceptance Criteria

- **Given** a profile renders text and UI controls
  **When** colors are applied
  **Then** all text and meaningful UI elements meet WCAG 2.2 AA contrast ratios

- **Given** a user sets a custom profile theme color
  **When** the color fails contrast against its background
  **Then** the system warns and adjusts or rejects the unreadable combination

## Notes
Enforce contrast in the design tokens, not only at render time.
