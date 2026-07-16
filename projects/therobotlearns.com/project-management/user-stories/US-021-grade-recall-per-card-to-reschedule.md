---
id: US-021
title: "Grade Recall Per Card to Reschedule It"
slug: grade-recall-per-card-to-reschedule
personas: [P-002, P-001]
epic: "Flashcards & Spaced Repetition"
priority: must-have
complexity: medium
tags: [flashcards, spaced-repetition, sm-2, grading]
---

# US-021: Grade Recall Per Card to Reschedule It

## User Story

**As a** learner reviewing flashcards
**I want to** grade my recall of each card using SM-2 quality ratings
**So that** the system reschedules the card's next review date based on how well I actually remembered it

## Acceptance Criteria

- **Given** a card's answer is revealed
  **When** I submit a quality rating (e.g., 0-5 scale)
  **Then** the card's ease factor, interval, and next-due date are recomputed per the SM-2 algorithm

- **Given** I rate a card poorly (recall failure)
  **When** the rating is saved
  **Then** the card's interval resets and it reappears soon rather than being pushed far into the future

- **Given** I rate a card with a high-quality response
  **When** the rating is saved
  **Then** the interval increases according to SM-2's ease-factor growth

- **Given** I finish rating a card
  **When** the next card loads
  **Then** my previous rating has already been persisted to disk before advancing

## Notes
