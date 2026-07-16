---
id: US-096
title: "Export flashcard decks to Anki"
slug: export-flashcard-decks-to-anki
personas: [P-002]
epic: "Integrations"
priority: should-have
complexity: medium
tags: [anki, export, flashcards]
---

# US-096: Export Flashcard Decks to Anki

## User Story

**As a** mid-level developer who studies flashcards on Anki on my phone
**I want to** export flashcard decks in a CSV/.apkg-compatible format
**So that** I can continue Anki-style spaced repetition on my phone using the Anki app

## Acceptance Criteria

- **Given** a deck of flashcards in the KB
  **When** the user runs the export command
  **Then** a CSV file compatible with Anki's import format is generated

- **Given** the exported CSV
  **When** imported into Anki (desktop or AnkiDroid)
  **Then** card front/back content and any tags or deck names are preserved correctly

- **Given** the KB's SM-2 scheduling data for a deck
  **When** exporting
  **Then** relevant scheduling metadata is either included or clearly noted as not transferred, so the user's expectations are set correctly

## Notes
CSV is the primary target; native .apkg generation may be a stretch goal noted separately if tooling permits.
