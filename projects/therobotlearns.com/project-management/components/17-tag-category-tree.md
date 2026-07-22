# Tag / Category Tree

| Field | Value |
|-------|-------|
| **ID** | `tag-category-tree` |
| **Category** | Navigation & Layout |
| **Used In** | 02-Knowledge Article Viewer, 03-KB Browse & Search |

## Description

A hierarchical tag/category browser for the KB, and the same structure used inline to edit an individual article's tags.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | Comma-separated tag list |
| **Compact** | Expandable tree, one level deep |
| **Expanded** | Full multi-level tree with per-node article counts |

## Props / Configuration

- `tree` — nested `{label, count, children}`
- `editable` — boolean (article-viewer context only)

## Interactions

- Expand/collapse nodes; in editable mode, add or remove an article's membership in a node.
