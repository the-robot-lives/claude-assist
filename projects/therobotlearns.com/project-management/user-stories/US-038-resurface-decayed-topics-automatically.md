---
id: US-038
title: "Resurface Decayed Topics Automatically"
slug: resurface-decayed-topics-automatically
personas: [P-001, P-002, P-008]
epic: "Learning Plans"
priority: could-have
complexity: medium
tags: [retention, decay, spaced-repetition, offline]
---

# US-038: Resurface Decayed Topics Automatically

## User Story

**As a** learner who wants long-term retention rather than just passing a quiz once
**I want to** have decayed or forgotten topics automatically resurfaced for review
**So that** knowledge I haven't touched in a while doesn't quietly fade

## Acceptance Criteria

- **Given** a topic's flashcards or quiz results haven't been reviewed in longer than its expected retention window
  **When** the daily review queue is built
  **Then** cards or refresher questions for that topic are automatically included even though I didn't request them

- **Given** decay detection runs
  **When** it operates
  **Then** it uses only local session and review history with no network calls, consistent with fully offline use

- **Given** a resurfaced topic is reviewed again
  **When** I complete that review
  **Then** its decay timer resets based on the new review outcome

## Notes
