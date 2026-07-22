---
id: US-083
title: "Resume an Interrupted Quiz or Simulation Session"
slug: resume-interrupted-quiz-simulation
personas: [P-003, P-002]
epic: "Resilience & Errors"
priority: must-have
complexity: medium
tags: [resilience, quiz, simulation, session-state]
---

# US-083: Resume an Interrupted Quiz or Simulation Session

## User Story

**As a** SRE who gets pulled away by on-call pages mid-quiz
**I want to** resume a quiz or simulation exactly where I left off
**So that** an interruption doesn't cost me my progress or force a restart

## Acceptance Criteria

- **Given** I am mid-quiz or mid-simulation and the session is interrupted (terminal closed, process killed, on-call page)
  **When** I next launch robot-learns
  **Then** it detects the incomplete session and offers to resume from the last answered question or simulation step

- **Given** I choose to resume
  **When** the session restarts
  **Then** my prior answers, elapsed time, and any partial scoring are restored exactly as they were

- **Given** I choose to abandon the interrupted session instead
  **When** I decline the resume prompt
  **Then** it's discarded cleanly and does not keep reappearing on every future launch

- **Given** the interruption happened due to a crash rather than a clean exit
  **When** robot-learns recovers
  **Then** it still finds valid resumable state, because progress is checkpointed incrementally rather than only on clean exit

## Notes
Checkpointing strategy should reuse the atomic-write guarantee from US-085 so a crash mid-write can't corrupt the resumable state itself.
