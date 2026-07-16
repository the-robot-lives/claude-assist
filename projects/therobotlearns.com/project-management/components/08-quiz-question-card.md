# Quiz Question Card

| Field | Value |
|-------|-------|
| **ID** | `quiz-question-card` |
| **Category** | Cards & Tiles |
| **Used In** | 06-Quiz Generator & Runner, 07-Quiz SPA |

## Description

A single quiz question in any of its supported types (multiple-choice, true/false, short-answer), rendered identically in logic between the terminal runner and the browser SPA so the same generated quiz JSON drives both.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Compact** | Question text plus answer options/input |
| **Expanded** | Question, options, and immediate correctness feedback plus explanation |
| **Full Page** | SPA-only — full-viewport single-question view with theme styling |

## Props / Configuration

- `type` — multiple-choice \| true-false \| short-answer
- `prompt`, `options`, `correctAnswer`, `explanation`

## Interactions

- Terminal: `@inquirer/prompts` selection/input. SPA: click/keyboard selection with animated feedback.
