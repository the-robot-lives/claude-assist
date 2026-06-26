---
id: US-891
title: "HTML lang Attribute Per Locale"
slug: page-language-attribute
personas: [P-010]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: low
tags: [i18n, language-attribute, screen-reader, wcag-2.2]
---

# US-891: HTML lang Attribute Per Locale

## User Story

**As a** screen-reader user
**I want to** the page language attribute to match my selected UI locale
**So that** my screen reader pronounces content correctly without requiring manual language switching

## Acceptance Criteria

- **Given** my UI locale is French
  **When** any page loads
  **Then** the root `<html>` element has `lang="fr"` set correctly

- **Given** I switch locale to Japanese in settings
  **When** the page updates
  **Then** `lang="ja"` is set on the root element without requiring a full page reload

- **Given** a post is written in a language different from the UI locale
  **When** the post is rendered in the feed
  **Then** that post's container element has a `lang` attribute matching the detected content language

## Notes
Use BCP 47 language tag format throughout (e.g., `en-US`, `pt-BR`). Content language detection should occur server-side during post indexing so the correct `lang` attribute is present in the initial HTML response.
