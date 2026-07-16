# Knowledge Article Viewer

| Field | Value |
|-------|-------|
| **ID** | `knowledge-article-viewer` |
| **Type** | Primary |
| **Category** | Knowledge Base |
| **User Stories** | US-008, US-009, US-013, US-015, US-016, US-071, US-099 |

## Description

The read view for a single saved knowledge article, whether reached by browsing, search, or a direct link from a `/query` answer. Shows the article body and its schema-defined metadata (tags, verification status, sources), and lets the user act on it: refresh, verify, tag, or open in an editor.

## Key Components

- **Calibrated Answer Block** — renders the article body (US-008)
- **Citation List** — sources backing the article (US-015)
- **Related Topics Chips** — suggestions surfaced while reading (US-071)
- **Tag/Category Tree** — inline tag editor for this article (US-013)

## Interactions

- Read an article rendered from its Markdown+YAML source directly in the terminal pager (US-008).
- Trigger a re-query to refresh a stale article in place (US-009).
- Mark an article `verified` after confirming its advice worked in practice (US-016).
- Add or remove tags and categories (US-013).
- Jump straight to `$EDITOR` on the underlying file for manual edits (US-099).
- Related-article chips update live as the user scrolls through the article (US-071).

## Navigation

- Accessible from: Query & Answer (after an answer saves), KB Browse & Search results, Session Log Viewer entries.
- Links to: KB Browse & Search, Query & Answer (refresh triggers a new query).
