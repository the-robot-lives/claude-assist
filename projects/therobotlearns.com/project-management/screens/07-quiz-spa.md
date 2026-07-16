# Quiz SPA

| Field | Value |
|-------|-------|
| **ID** | `quiz-spa` |
| **Type** | Primary |
| **Category** | Quizzes |
| **User Stories** | US-026, US-052, US-089, US-091 |

## Description

The one genuine browser screen in the product — a standalone single-HTML-file React quiz runner (Vite build) offering a richer visual alternative to the terminal quiz for the same generated quiz format. Themeable across the four design-system directions (Scholar, Atlas, Spark, Deep Focus) and built to WCAG 2.2 AA.

## Key Components

- **Quiz Question Card** — same logical component as the terminal runner, browser-rendered (US-026)
- **Score / Results Summary** — end-of-quiz results (US-026)
- **Theme Picker** — scholar / atlas / spark / deep-focus (US-052)
- **Accessibility Toggle** — text size and high-contrast controls (US-091)

## Interactions

- Open the same generated quiz in a browser tab instead of the terminal (US-026).
- Pick a visual theme for comfort and contrast (US-052).
- Navigate fully by keyboard and screen reader, meeting WCAG 2.2 AA (US-089).
- Adjust text size and switch to a high-contrast theme independent of the base theme choice (US-091).

## Navigation

- Accessible from: Quiz Generator & Runner's "open in browser" action, or a shareable local file link.
- Links to: back to Quiz Generator & Runner once results sync to the terminal-side result store.
