---
id: US-772
title: "Select Date and Time Format"
slug: select-date-and-time-format
personas: [P-010]
epic: "Settings & Preferences"
priority: should-have
complexity: low
tags: [locale, date-format, time-format, preferences]
---

# US-772: Select Date and Time Format

## User Story

**As a** skeptical switcher
**I want to** set my preferred date and time format (e.g. DD/MM/YYYY vs MM/DD/YYYY, 12h vs 24h)
**So that** timestamps throughout the app match my regional conventions.

## Acceptance Criteria

- **Given** I open Language & Locale
  **When** I choose "24-hour clock" and "DD/MM/YYYY"
  **Then** all timestamps in posts, notifications, and settings reflect those formats.

## Notes
Format preferences default to the locale implied by the selected display language but can be overridden independently.
