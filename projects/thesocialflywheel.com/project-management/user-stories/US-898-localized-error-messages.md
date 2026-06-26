---
id: US-898
title: "Localized Error Messages"
slug: localized-error-messages
personas: [P-010]
epic: "Accessibility & Internationalization"
priority: should-have
complexity: low
tags: [error-messaging, i18n, localization]
---

# US-898: Localized Error Messages

## User Story

**As a** Skeptical Switcher using the platform in a non-English locale
**I want to** all error messages, validation feedback, and system alerts to appear in my selected language
**So that** I understand exactly what went wrong without needing to mentally translate English error text

## Acceptance Criteria

- **Given** my locale is Spanish
  **When** a form validation error fires
  **Then** the error text is rendered in Spanish, not English

- **Given** my locale is Japanese
  **When** the server returns an error code (e.g., 403, 429)
  **Then** the mapped user-facing message is shown in Japanese

- **Given** no translation exists for a specific error string in my locale
  **When** the error is displayed
  **Then** it falls back to English gracefully — never exposing a raw error code or translation key to the user

## Notes
Error messages should be treated as first-class translatable content in the i18n catalog, not hardcoded developer strings. Server-returned error codes must map to locale-aware message keys client-side.
