---
id: US-872
title: "Plain-Language Mode Toggle"
slug: plain-language-mode
personas: [P-001]
epic: "Accessibility & Internationalization"
priority: should-have
complexity: medium
tags: [cognitive-load, plain-language, accessibility]
---

# US-872: Plain-Language Mode Toggle

## User Story

**As a** Bridge-Builder
**I want to** use a plain-language mode that simplifies channel descriptions, lane labels, and onboarding text
**So that** I can navigate complex concepts like degrees and lanes without jargon

## Acceptance Criteria

- **Given** plain-language mode is enabled
  **When** I view lane labels
  **Then** "Opposing-Views" displays as "Other Perspectives" and degree labels read "Friend of a friend" etc.

- **Given** plain-language mode is on
  **When** I see a "Why am I seeing this" explanation
  **Then** it uses short sentences under 20 words

- **Given** I disable plain-language mode
  **When** the UI refreshes
  **Then** original terminology is restored

## Notes
Plain-language strings should live in the same i18n catalog as other locale strings, using a `plain.` namespace prefix, so they can be translated independently; the toggle state should persist in the user's account preferences.
