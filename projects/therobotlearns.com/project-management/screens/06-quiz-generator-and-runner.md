# Quiz Generator & Runner

| Field | Value |
|-------|-------|
| **ID** | `quiz-generator-and-runner` |
| **Type** | Primary |
| **Category** | Quizzes |
| **User Stories** | US-024, US-025, US-027, US-028, US-029, US-083, US-088 |

## Description

The terminal quiz experience: generate a quiz from a topic or article, take it via interactive prompts, and get results with weak-area analysis. The screen-reader-friendly linear CLI mode lives here specifically, so a blind user can complete a quiz without depending on ASCII-art layout.

## Key Components

- **Quiz Question Card** — the current question and its options (US-024, US-029)
- **Score / Results Summary** — end-of-quiz weak-area breakdown (US-027)
- **Progress Bar / Milestone Tracker** — "question N of M" (US-025)
- **Accessibility Toggle** — linear screen-reader mode (US-088)

## Interactions

- Generate a quiz on a topic or specific article via `/quiz` (US-024).
- Answer questions through `@inquirer/prompts`-driven terminal prompts (US-025).
- Questions mix multiple-choice, true/false, and short-answer types (US-029).
- Results are stored and analyzed to identify weak areas (US-027).
- Retake only the questions missed on the last attempt (US-028).
- Resume a quiz exactly where an interruption (e.g. an on-call page) left it (US-083).
- Switch to a linear, screen-reader-friendly mode that drops spatial/ASCII cues (US-088).

## Navigation

- Accessible from: the `/quiz` command directly, or Flashcard Decks & Review ("quiz me on this deck").
- Links to: Quiz SPA (same quiz, browser renderer), Learning Plan Dashboard (results feed plan adaptation).
