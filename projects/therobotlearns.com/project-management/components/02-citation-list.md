# Citation List

| Field | Value |
|-------|-------|
| **ID** | `citation-list` |
| **Category** | Data Display |
| **Used In** | 01-Query & Answer, 02-Knowledge Article Viewer, 09-Graded Projects |

## Description

An ordered list of sources backing a generated answer, article, or piece of grading feedback, letting the user verify claims instead of trusting the agent blindly.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | Trailing `[1][2][3]` marker set with footnote-style references |
| **Compact** | Short "Sources:" block listing 1–3 links or titles |
| **Expanded** | Full bibliography with URLs, retrieval dates, and confidence notes |

## Props / Configuration

- `sources` — array of `{title, url|path, retrieved_at}`
- `style` — inline \| block

## Interactions

- Selecting a citation (or its number) opens the source in `$PAGER`/`$EDITOR` or the browser.
