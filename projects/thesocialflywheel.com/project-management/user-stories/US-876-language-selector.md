---
id: US-876
title: "Language Selector in Settings"
slug: language-selector
personas: [P-010]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: low
tags: [localization, i18n, settings]
---

# US-876: Language Selector in Settings

## User Story

**As a** Skeptical Switcher
**I want to** select my preferred UI language from a settings menu
**So that** I can use the platform in my native language from day one

## Acceptance Criteria

- **Given** I open Account Settings
  **When** I navigate to Language & Region
  **Then** a dropdown lists all supported locales with their native-language names

- **Given** I select a new language
  **When** I confirm
  **Then** the UI reloads in the selected language without requiring me to log out

- **Given** my browser's `Accept-Language` header indicates a supported locale
  **When** I first register
  **Then** the UI defaults to that locale

## Notes
Locale names in the dropdown must be rendered in the locale's own script (e.g., "Deutsch", "日本語", "العربية") rather than in English, to be usable by someone who does not yet read the current UI language.
