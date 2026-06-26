---
id: US-877
title: "Fully Localized UI Strings"
slug: localized-ui-strings
personas: [P-010]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: high
tags: [localization, i18n, strings]
---

# US-877: Fully Localized UI Strings

## User Story

**As a** Skeptical Switcher
**I want to** see every UI label, button, placeholder, and system message in my selected language
**So that** I do not encounter untranslated English strings while using the platform

## Acceptance Criteria

- **Given** French locale is selected
  **When** I navigate the entire app
  **Then** no hardcoded English strings remain in nav, buttons, or tooltips

- **Given** a new UI string is added in development
  **When** the build runs
  **Then** a CI check fails if the string lacks a translation key in the default locale file

- **Given** a translation is missing for my locale
  **When** the string is displayed
  **Then** it falls back to English without exposing raw translation keys to the user

## Notes
Use an i18n framework (e.g., i18next or ICU MessageFormat) with a key-based string catalog. Raw translation key exposure (e.g., "settings.account.title") is never acceptable in production.
