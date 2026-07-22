---
id: US-090
title: "Receive content in preferred language"
slug: preferred-language-content
personas: [P-005]
epic: "Accessibility & i18n"
priority: should-have
complexity: medium
tags: [i18n, localization]
---

# US-090: Receive Content in Preferred Language

## User Story

**As a** Portuguese-first career-switcher junior developer
**I want to** receive quiz answers, feedback, and generated content in my preferred language
**So that** I can learn without a language barrier slowing comprehension

## Acceptance Criteria

- **Given** the user has set a preferred language (e.g., pt-BR) in their config
  **When** the agent generates new flashcards, quizzes, or feedback
  **Then** the generated text is produced in that language

- **Given** existing KB content is in English
  **When** the user requests a translated version of an article or deck
  **Then** the agent produces a translated copy while preserving the original English source

- **Given** the quiz-cli or SPA renders UI chrome (labels, buttons, status messages)
  **When** the preferred language is set
  **Then** UI strings render in that language where translations exist, falling back to English otherwise

## Notes
Language preference should be a single config value read by both the CLI and SPA so it doesn't need to be set twice.
