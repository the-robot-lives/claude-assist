# Search Input Bar

| Field | Value |
|-------|-------|
| **ID** | `search-input-bar` |
| **Category** | Input & Forms |
| **Used In** | 03-KB Browse & Search, 04-Session Log Viewer, 05-Flashcard Decks & Review |

## Description

A consistent full-text query bar with optional filters (date range, tag, content type), reused everywhere something needs to be found rather than browsed.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | Bare text input |
| **Compact** | Input plus type-scope toggle (articles/cards/quizzes/sessions) |
| **Expanded** | Input plus full filter panel (date range, tags, verified-only) |

## Props / Configuration

- `query`, `scope`, `filters`

## Interactions

- Live-narrows results as the user types; Enter runs the full query.
