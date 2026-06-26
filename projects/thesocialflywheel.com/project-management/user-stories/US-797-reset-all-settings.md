---
id: US-797
title: "Reset All Settings to Defaults"
slug: reset-all-settings-to-defaults
personas: [P-001]
epic: "Settings & Preferences"
priority: could-have
complexity: medium
tags: [settings, reset, defaults, nuclear-option]
---

# US-797: Reset All Settings to Defaults

## User Story

**As a** bridge-builder
**I want to** reset every preference to factory defaults in a single action
**So that** I can start a fresh configuration after experimenting extensively with settings

## Acceptance Criteria

- **Given** I open Settings > Advanced
  **When** I tap "Reset All Settings", enter my password to confirm
  **Then** all settings categories revert to defaults, excluding account credentials and blocked user list.

- **Given** all settings are reset
  **When** I view each settings page
  **Then** all values match the documented factory defaults and a timestamp showing "Reset on [date]" is shown at the top of the settings root.

## Notes
Block lists and explicit safety configurations (exclusions) are intentionally excluded from reset to prevent accidental re-exposure to harmful content.
