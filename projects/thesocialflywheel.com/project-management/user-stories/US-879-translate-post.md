---
id: US-879
title: "Inline Post Translation"
slug: translate-post
personas: [P-001]
epic: "Accessibility & Internationalization"
priority: should-have
complexity: medium
tags: [translation, i18n, content]
---

# US-879: Inline Post Translation

## User Story

**As a** Bridge-Builder
**I want to** translate any post into my preferred language with one click
**So that** language barriers do not prevent me from engaging across communities

## Acceptance Criteria

- **Given** a post is written in a language different from my UI locale
  **When** I press "Translate post"
  **Then** the post body is replaced with translated text and a "Show original" link appears beneath it

- **Given** I click "Show original"
  **When** it renders
  **Then** the original text is fully restored

- **Given** the translation service is unavailable
  **When** I press "Translate post"
  **Then** an accessible inline error message reads "Translation unavailable. Try again later." and focus remains on the post

## Notes
Translation is applied client-side and ephemeral; it does not alter the stored post. The "Translate" button must be keyboard accessible and screen-reader labelled "Translate post from [detected language]".
