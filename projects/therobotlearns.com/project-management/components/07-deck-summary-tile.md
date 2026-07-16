# Deck Summary Tile

| Field | Value |
|-------|-------|
| **ID** | `deck-summary-tile` |
| **Category** | Cards & Tiles |
| **Used In** | 03-KB Browse & Search, 05-Flashcard Decks & Review |

## Description

A per-deck summary — name, total cards, and due-today count — used to decide which deck to review or to locate one while browsing.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | `deck-name (4 due)` |
| **Compact** | Name, due/total counts, and last-reviewed date |
| **Expanded** | Full card list preview |

## Props / Configuration

- `deck`, `due_count`, `total_count`, `last_reviewed_at`

## Interactions

- Selecting a tile jumps into that deck's review queue.
