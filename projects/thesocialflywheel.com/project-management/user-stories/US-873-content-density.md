---
id: US-873
title: "Content Density Control"
slug: content-density
personas: [P-006]
epic: "Accessibility & Internationalization"
priority: could-have
complexity: medium
tags: [cognitive-load, density, accessibility]
---

# US-873: Content Density Control

## User Story

**As a** Quiet Consumer
**I want to** choose between compact, standard, and comfortable content density
**So that** I can control how much information is displayed per screen

## Acceptance Criteria

- **Given** I open Display Settings
  **When** I select "Comfortable" density
  **Then** post cards have increased line-height and padding compared to "Standard"

- **Given** I select "Compact" density
  **When** I view the feed
  **Then** post metadata (degree badge, timestamp, channel) collapses to a single line

- **Given** I change density
  **When** the setting is saved
  **Then** the preference persists across sessions and devices

## Notes
Density should be implemented via CSS custom properties (e.g., `--density-spacing-unit`) scoped to a `data-density` attribute on the root layout element, enabling instant switching without a full re-render.
