---
id: US-088
title: "Screen-reader-friendly terminal output"
slug: screen-reader-friendly-terminal-output
personas: [P-007]
epic: "Accessibility & i18n"
priority: must-have
complexity: medium
tags: [accessibility, cli, screen-reader]
---

# US-088: Screen-Reader-Friendly Terminal Output

## User Story

**As a** blind senior developer using a screen reader
**I want to** run quizzes in a linear, screen-reader-friendly CLI mode
**So that** I can complete quizzes without relying on visual ASCII art or spatial layout cues

## Acceptance Criteria

- **Given** the quiz-cli is launched
  **When** accessible mode is active (auto-detected or set via flag/env var)
  **Then** all prompts render as linear sequential text with no meaning conveyed only through ASCII art or spatial layout

- **Given** a question includes a diagram or ASCII chart
  **When** rendered in accessible mode
  **Then** an equivalent text description is provided alongside or instead of the visual

- **Given** the user is navigating prompts built with @inquirer/prompts
  **When** a prompt renders
  **Then** the screen reader announces the question text, available choices, and the current selection state

- **Given** the user submits an answer
  **When** feedback is shown (correct/incorrect)
  **Then** the result is announced as text, not conveyed only through color or symbols

## Notes
Accessible mode should be discoverable (env var or CLI flag) and ideally auto-detected from common screen-reader environment signals where feasible.
