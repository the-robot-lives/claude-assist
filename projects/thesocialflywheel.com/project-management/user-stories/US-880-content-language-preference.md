---
id: US-880
title: "Content Language Preference Filter"
slug: content-language-preference
personas: [P-010]
epic: "Accessibility & Internationalization"
priority: should-have
complexity: medium
tags: [i18n, language-preferences, feed]
---

# US-880: Content Language Preference Filter

## User Story

**As a** Skeptical Switcher
**I want to** specify which content languages I prefer to see in my feed
**So that** I am not flooded with posts I cannot read

## Acceptance Criteria

- **Given** I open Language & Region settings and select English and Spanish as preferred content languages
  **When** the Discovery and Opposing-Views lanes load
  **Then** only posts detected as English or Spanish are shown

- **Given** Mutuals lane is active
  **When** a moot posts in a non-preferred language
  **Then** their post still appears with a visible "Translate" option rather than being hidden

- **Given** I add a new language to my preferences
  **When** I save the setting
  **Then** the feed refreshes immediately to include matching posts without a full page reload

## Notes
Mutuals lane must never suppress posts from direct connections regardless of language preference — hiding moots' content would damage the social graph experience.
