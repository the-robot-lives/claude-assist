---
id: US-395
title: "Bootstrap Cold Start from Onboarding Topic Quiz"
slug: bootstrap-cold-start-from-onboarding-topic-quiz
personas: [P-001]
epic: "Discovery Engine"
priority: must-have
complexity: medium
tags: [discovery, cold-start, onboarding]
---

# US-395: Bootstrap Cold Start from Onboarding Topic Quiz

## User Story

**As a** Bridge-Builder
**I want to** have my onboarding quiz answers immediately seed my discovery engine with relevant content
**So that** my first experience of the platform feels personalized from the very first session

## Acceptance Criteria

- **Given** I complete the onboarding interest quiz and confirm my selections
  **When** my feed is generated for the first time
  **Then** discovery items drawn from those quiz-selected interests are present in the feed before I have followed anyone

- **Given** I selected interests in the quiz
  **When** I begin following mutuals whose interests overlap with my quiz selections
  **Then** the engine blends quiz-based cold-start content with graph-sourced content, progressively reducing the quiz content share as the graph grows

## Notes
Quiz-seeded content is sourced from staff-curated and high-quality posts in the selected interest channels to ensure a positive first impression.
