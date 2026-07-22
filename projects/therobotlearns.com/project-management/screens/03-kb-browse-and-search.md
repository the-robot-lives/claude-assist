# KB Browse & Search

| Field | Value |
|-------|-------|
| **ID** | `kb-browse-and-search` |
| **Type** | Primary |
| **Category** | Search & Discovery |
| **User Stories** | US-066, US-067, US-068, US-070, US-072, US-073 |

## Description

The discovery surface for everything already in the KB: full-text search across articles, a tag/category browse tree, a recent-activity feed, a "serendipity" random-resurfacing mode, and a knowledge-gaps report that points at what's adjacent but missing.

## Key Components

- **Search Input Bar** — full-text query across article bodies (US-066)
- **Tag/Category Tree** — hierarchical browse alternative to search (US-068)
- **Deck Summary Tile** — flashcard/quiz results mixed into search (US-067)
- **Related Topics Chips** — gap-report suggestions (US-070)

## Interactions

- Full-text query across article bodies, not just titles or tags (US-066).
- Search extends to flashcard decks and quizzes by topic, not just articles (US-067).
- Browse via a tag/category tree instead of searching (US-068).
- View a feed of recently added or updated articles (US-072).
- Trigger serendipity mode to resurface a random older article for review (US-073).
- Run a knowledge-gaps report listing adjacent-but-uncovered topics (US-070).

## Navigation

- Accessible from: any screen via `/query --browse` or a standalone browse/search command; Learning Plan Dashboard links here when it recommends filling a gap.
- Links to: Knowledge Article Viewer, Flashcard Decks & Review.
