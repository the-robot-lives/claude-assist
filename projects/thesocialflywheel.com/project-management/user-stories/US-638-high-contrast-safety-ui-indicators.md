---
id: US-638
title: "High-Contrast Safety UI Indicators"
slug: high-contrast-safety-ui-indicators
personas: [P-008]
epic: "Safety: Blocking & Exclusions"
priority: should-have
complexity: low
tags: [safety, accessibility]
---

# US-638: High-Contrast Safety UI Indicators

## User Story

**As an** accessibility-first user
**I want to** see all safety indicators (blocked, muted, excluded) in a high-contrast theme
**So that** safety-related status is clearly distinguishable even with low vision

## Acceptance Criteria

- **Given** high-contrast mode is enabled in my accessibility settings
  **When** I view the Blocked Users or Exclusion list
  **Then** all status badges and action buttons meet WCAG AA 4.5:1 contrast ratio

- **Given** a "Mutual of blocked person" indicator is shown on a profile card in high-contrast mode
  **When** I inspect the badge
  **Then** it uses a border or icon rather than colour alone to convey status

## Notes
Colour-blind-safe palette required; do not rely on red/green distinction alone.
