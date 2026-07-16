---
id: US-050
title: "Set Learning-Style Preferences"
slug: set-learning-style-preferences
personas: [P-005, P-002]
epic: "Settings & Preferences"
priority: should-have
complexity: low
tags: [settings, learning-style, personalization]
---

# US-050: Set Learning-Style Preferences

## User Story

**As a** learner with a preferred way of absorbing new material
**I want to** set my learning-style preferences (examples-first vs theory-first, verbosity)
**So that** KB articles, `/query` answers, and explanations match how I actually learn best

## Acceptance Criteria

- **Given** I open my learning-style settings
  **When** I view the available options
  **Then** I can choose between examples-first and theory-first explanation style.

- **Given** I set a verbosity preference
  **When** I choose from concise, standard, or detailed
  **Then** subsequent explanations and articles are generated at that length by default.

- **Given** I change my learning style mid-project
  **When** the change is saved
  **Then** it applies to new content going forward without regenerating my existing KB articles.

- **Given** I haven't set a learning-style preference yet
  **When** the system needs one
  **Then** it falls back to a sensible documented default rather than failing.
