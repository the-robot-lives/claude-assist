# Flashcard

| Field | Value |
|-------|-------|
| **ID** | `flashcard` |
| **Category** | Cards & Tiles |
| **Used In** | 05-Flashcard Decks & Review, 16-Import / Export & Sharing |

## Description

The atomic spaced-repetition unit: a front/back pair plus SM-2 scheduling metadata (ease factor, interval, next-due date).

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | Front text only, truncated, for list views |
| **Compact** | Front, with back revealed on demand, plus current due date |
| **Expanded** | Full SM-2 history (past grades, interval changes) |

## Props / Configuration

- `front`, `back` — card content
- `ease`, `interval`, `due_at` — SM-2 scheduling state
- `deck` — owning deck slug

## Interactions

- Space/Enter reveals the back in review mode; grading keys (1–4) record recall quality and reschedule the card.
