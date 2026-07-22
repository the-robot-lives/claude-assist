# Score / Results Summary

| Field | Value |
|-------|-------|
| **ID** | `score-results-summary` |
| **Category** | Data Display |
| **Used In** | 06-Quiz Generator & Runner, 07-Quiz SPA, 08-Simulation Room, 09-Graded Projects |

## Description

The end-of-attempt results block — score, pass/fail or grade, and a weak-areas breakdown — reused across quizzes, simulations, and graded projects since all three end in an evaluated outcome.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | `7/10 (70%)` single line |
| **Compact** | Score plus top 2–3 weak areas |
| **Expanded** | Full per-question or per-criterion breakdown with rationale |

## Props / Configuration

- `score`, `total`
- `breakdown` — array of `{topic|criterion, result, note}`

## Interactions

- Selecting a weak-area entry offers a direct action (retake missed questions, generate a flashcard deck for that topic).
