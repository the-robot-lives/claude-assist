# Session Log Entry

| Field | Value |
|-------|-------|
| **ID** | `session-log-entry` |
| **Category** | Tables & Lists |
| **Used In** | 04-Session Log Viewer, 10-Learning Plan Dashboard |

## Description

A single row summarizing one Q&A session — date, topic(s) touched, and duration — the building block of the session log and of the dashboard's recent-activity list.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | `2026-07-15 — Kubernetes networking (12m)` |
| **Compact** | Row plus question count and articles created |
| **Expanded** | Full transcript of the session's questions and answer links |

## Props / Configuration

- `date`, `topics`, `duration`, `questionCount`, `articlesCreated`

## Interactions

- Selecting a row opens the expanded transcript; selecting a topic chip jumps to that article.
