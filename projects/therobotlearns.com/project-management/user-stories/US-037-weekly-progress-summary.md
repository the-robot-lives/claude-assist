---
id: US-037
title: "Get a Weekly Progress Summary"
slug: weekly-progress-summary
personas: [P-001, P-002, P-004]
epic: "Learning Plans"
priority: should-have
complexity: medium
tags: [progress-summary, retention, reporting]
---

# US-037: Get a Weekly Progress Summary

## User Story

**As a** daily user of the tool
**I want to** get a weekly progress summary of my learning and retention
**So that** I can reflect on the past week and decide where to focus next

## Acceptance Criteria

- **Given** a week of session logs, flashcard reviews, and quiz attempts
  **When** the weekly summary is generated
  **Then** it reports cards reviewed, quizzes taken, retention rate, and topics covered

- **Given** the summary is generated
  **When** I view it
  **Then** it highlights notable trends, such as topics improving or slipping compared to the prior week

- **Given** a team lead wants a rollup for their own study across a team's shared domains
  **When** they request the summary
  **Then** it's scoped to their own local data only, with no cross-user data access implied

## Notes
