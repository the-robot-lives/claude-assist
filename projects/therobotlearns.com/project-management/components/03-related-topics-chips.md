# Related Topics Chips

| Field | Value |
|-------|-------|
| **ID** | `related-topics-chips` |
| **Category** | Navigation & Layout |
| **Used In** | 01-Query & Answer, 02-Knowledge Article Viewer, 03-KB Browse & Search |

## Description

A row of short topic suggestions surfaced after an answer, while reading an article, or as part of a gap report — the mechanism behind "what should I learn next."

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | Single-line, comma-separated chip row |
| **Compact** | 3–5 chips with a one-line description each |
| **Expanded** | Full gap-report list with rationale per suggestion |

## Props / Configuration

- `topics` — array of `{label, rationale, covered: boolean}`
- `source` — adjacent-topic \| gap-report \| serendipity

## Interactions

- Selecting a chip launches a `/query` for that topic directly.
