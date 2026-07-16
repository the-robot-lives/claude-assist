# Session Log Viewer

| Field | Value |
|-------|-------|
| **ID** | `session-log-viewer` |
| **Type** | Primary |
| **Category** | Knowledge Base |
| **User Stories** | US-011, US-012 |

## Description

A chronological log of every Q&A session: what was asked, when, and what came out of it. Exists so users can retrace their own learning history — for example, before a review or an interview.

## Key Components

- **Search Input Bar** — filter sessions by date or topic (US-012)
- **Session Log Entry** — a single session's row summary (US-011)

## Interactions

- Every `/query` session is appended to the log automatically, with no user action required (US-011).
- Browse and filter past sessions by date or topic to retrace what was learned (US-012).

## Navigation

- Accessible from: Query & Answer at session end, or a standalone `/sessions` command.
- Links to: Knowledge Article Viewer (jump to an article referenced in a session), Learning Plan Dashboard.
