---
id: US-775
title: "Adjust Font Size Scale"
slug: adjust-font-size-scale
personas: [P-008]
epic: "Settings & Preferences"
priority: must-have
complexity: low
tags: [accessibility, font-size, readability, text]
---

# US-775: Adjust Font Size Scale

## User Story

**As an** accessibility-first user
**I want to** adjust the app's base font size scale
**So that** text is legible without me having to rely solely on my device's system font size.

## Acceptance Criteria

- **Given** I open Accessibility Settings
  **When** I move the font size slider from 100% to 140%
  **Then** all body text, labels, and buttons scale proportionally and the layout reflows without clipping.

- **Given** I have set a custom font scale
  **When** I update the app
  **Then** my font size preference is preserved.

## Notes
Scale range is 80%–200%. Values above 150% trigger a layout audit warning in QA to catch clipping regressions.
