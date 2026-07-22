---
id: US-052
title: "Choose a Visual Theme for the Quiz SPA"
slug: choose-visual-theme-for-quiz-spa
personas: [P-007, P-002]
epic: "Settings & Preferences"
priority: should-have
complexity: medium
tags: [settings, theme, accessibility, quiz]
---

# US-052: Choose a Visual Theme for the Quiz SPA

## User Story

**As a** user with specific visual and contrast needs
**I want to** choose a visual theme for the quiz SPA from scholar, atlas, spark, and deep-focus
**So that** quizzes are comfortable and accessible for how I read the screen

## Acceptance Criteria

- **Given** I open the quiz SPA settings
  **When** I view available themes
  **Then** I can preview and select from scholar, atlas, spark, and deep-focus.

- **Given** I rely on a screen reader and need high contrast
  **When** I select a theme
  **Then** the theme's contrast ratios meet WCAG AA at minimum, and this is documented per theme.

- **Given** I select a new theme
  **When** I launch or reload the quiz SPA
  **Then** the change applies without requiring a reinstall or manual config editing.

- **Given** I use keyboard-only or screen-reader navigation
  **When** I browse and select themes
  **Then** the theme picker itself is fully operable via keyboard with proper ARIA labeling.
