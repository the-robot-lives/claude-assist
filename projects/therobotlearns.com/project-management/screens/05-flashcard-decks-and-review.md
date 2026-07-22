# Flashcard Decks & Review

| Field | Value |
|-------|-------|
| **ID** | `flashcard-decks-and-review` |
| **Type** | Primary |
| **Category** | Flashcards & Spaced Repetition |
| **User Stories** | US-019, US-020, US-021, US-022, US-023, US-038, US-096 |

## Description

Where spaced-repetition practice happens. Generates flashcards from KB articles, organizes them into topic decks, runs the daily SM-2-scheduled review queue, and grades recall to reschedule each card.

## Key Components

- **Flashcard** — the front/back review unit (US-021)
- **Deck Summary Tile** — due/total counts per deck (US-022, US-023)
- **Search Input Bar** — find a deck by topic (US-023)
- **Progress Bar / Milestone Tracker** — progress through today's queue (US-020)

## Interactions

- Generate a flashcard set from any KB article via `/flashcard` (US-019).
- See the day's due-card queue, computed by the SM-2 algorithm (US-020).
- Grade recall per card (again/hard/good/easy) to reschedule its next review (US-021).
- See due-card counts per deck before committing to a review session (US-022).
- Cards are auto-organized into topic decks tracked by a central index (US-023).
- Decayed or forgotten topics are automatically resurfaced into the queue (US-038).
- Export a deck to Anki-compatible CSV/`.apkg` for phone-based review (US-096).

## Navigation

- Accessible from: Knowledge Article Viewer's "generate flashcards" action, or the standalone `/flashcard` command.
- Links to: Quiz Generator & Runner (a deck can seed a quiz), KB Browse & Search, Import / Export & Sharing.
