---
id: US-008
title: "Browse a Knowledge Article from the Terminal"
slug: browse-knowledge-article-terminal
personas: [P-001, P-007]
epic: "Calibrated Q&A"
priority: must-have
complexity: low
tags: [terminal-ui, browse, accessibility]
---

# US-008: Browse a Knowledge Article from the Terminal

## User Story

**As a** terminal-native developer
**I want to** read and browse a knowledge article from the terminal
**So that** I can reference past answers without leaving my workflow

## Acceptance Criteria

- **Given** I know an article's topic or title
  **When** I run the browse command
  **Then** the article's content is rendered readably in the terminal

- **Given** I don't know the exact title
  **When** I search or browse by keyword
  **Then** matching articles are listed for selection

- **Given** I use a screen reader
  **When** an article is rendered
  **Then** the output uses plain, linearly-readable text without relying on color or box-drawing characters to convey meaning

## Notes
Screen-reader accessibility here directly serves P-007; avoid ANSI-art-heavy formatting for article bodies.
