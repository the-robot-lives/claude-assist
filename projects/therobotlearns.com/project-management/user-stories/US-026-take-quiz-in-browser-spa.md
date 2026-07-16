---
id: US-026
title: "Take a Quiz in the Browser SPA"
slug: take-quiz-in-browser-spa
personas: [P-002, P-005]
epic: "Quizzes"
priority: could-have
complexity: medium
tags: [quiz, react-spa, browser]
---

# US-026: Take a Quiz in the Browser SPA

## User Story

**As a** learner who sometimes prefers a visual interface
**I want to** take the same generated quiz in a single-file React SPA in my browser
**So that** I have a richer, more visual alternative to the terminal runner

## Acceptance Criteria

- **Given** a saved quiz
  **When** I generate its SPA
  **Then** a single self-contained HTML file is produced that requires no separate server to run

- **Given** I open the SPA in a browser
  **When** I answer questions
  **Then** the interface presents the same questions, options, and correctness logic as the terminal quiz-cli

- **Given** I complete the quiz in the SPA
  **When** I finish
  **Then** results are exported or saved in a format compatible with the same results store used by quiz-cli

## Notes
