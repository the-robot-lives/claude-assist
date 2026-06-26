---
id: US-878
title: "Locale-Aware Date and Number Formatting"
slug: locale-formatting
personas: [P-010]
epic: "Accessibility & Internationalization"
priority: should-have
complexity: low
tags: [i18n, formatting, dates, numbers]
---

# US-878: Locale-Aware Date and Number Formatting

## User Story

**As a** Skeptical Switcher
**I want to** see dates, times, and large numbers formatted according to my locale
**So that** timestamps and counts are immediately readable without mental translation

## Acceptance Criteria

- **Given** German locale is selected
  **When** I see a post timestamp
  **Then** it displays in DD.MM.YYYY format

- **Given** US locale is selected
  **When** follower counts exceed 1000
  **Then** they display as "1,234" with commas as thousands separators

- **Given** Japanese locale is selected
  **When** times are displayed
  **Then** 24-hour format is used by default matching local convention

## Notes
Use the browser-native `Intl.DateTimeFormat` and `Intl.NumberFormat` APIs for formatting; avoid custom date libraries that require manual locale data maintenance.
