---
id: US-770
title: "Follow System Theme"
slug: follow-system-theme
personas: [P-010]
epic: "Settings & Preferences"
priority: should-have
complexity: low
tags: [theme, appearance, system, automation]
---

# US-770: Follow System Theme

## User Story

**As a** skeptical switcher
**I want to** have the app automatically match my device's light/dark mode setting
**So that** I do not have to maintain a separate preference inside the app.

## Acceptance Criteria

- **Given** I select "Follow System" in Appearance Settings
  **When** my device switches from light to dark mode
  **Then** the app theme changes in real time without me manually updating settings.

## Notes
"Follow System" is the default for new accounts; users who explicitly pick light or dark opt out of automatic switching.
