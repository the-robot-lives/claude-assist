---
id: US-397
title: "High-Contrast Discovery Badge for Accessibility"
slug: high-contrast-discovery-badge-for-accessibility
personas: [P-006]
epic: "Discovery Engine"
priority: should-have
complexity: low
tags: [discovery, accessibility, contrast]
---

# US-397: High-Contrast Discovery Badge for Accessibility

## User Story

**As a** Quiet Consumer with low vision
**I want to** have the discovery badge displayed in high-contrast colors that are legible in all display modes
**So that** I can distinguish discovery items without needing to increase system font size or use zoom

## Acceptance Criteria

- **Given** the app is in standard light mode
  **When** a discovery badge is rendered
  **Then** the badge text and background meet a minimum 4.5:1 contrast ratio per WCAG 2.1 AA

- **Given** the app is in dark mode or high-contrast mode
  **When** a discovery badge is rendered
  **Then** the badge maintains at least 4.5:1 contrast ratio in the active color scheme

## Notes
Badge colors must be defined in the design token system so they automatically adapt to all supported themes.
