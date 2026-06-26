---
id: US-437
title: "Set post language for translation and routing"
slug: choose-post-language
personas: [P-008]
epic: "Posting & Content Creation"
priority: could-have
complexity: low
tags: [language, accessibility, i18n, routing]
---

# US-437: Set Post Language for Translation and Routing

## User Story

**As an** Accessibility-First user
**I want to** declare the language of my post
**So that** screen readers announce it correctly and recipients' auto-translation features activate appropriately

## Acceptance Criteria

- **Given** I am composing a post
  **When** I select a language from the language picker (defaulting to my account language)
  **Then** the declared language is stored with the post

- **Given** a recipient's device language differs from the post language
  **When** they view the post
  **Then** an inline "Translate" option is offered

## Notes
Auto-detect language from text is offered as a convenience but user can override. Screen readers use the lang attribute.
