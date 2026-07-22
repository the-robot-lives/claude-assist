# Learning Plan Dashboard

| Field | Value |
|-------|-------|
| **ID** | `learning-plan-dashboard` |
| **Type** | Dashboard |
| **Category** | Learning Plans |
| **User Stories** | US-034, US-035, US-036, US-037 |

## Description

The goal-tracking home screen for a structured, multi-week learning plan: create one from a goal, check off milestones, watch it adapt to actual quiz/flashcard performance, and get a weekly summary.

## Key Components

- **Progress Bar / Milestone Tracker** — plan milestones (US-035)
- **KB Stat Tile** — weekly summary metrics (US-037)
- **Expertise Level Badge** — domain levels the plan is calibrated against (US-036)
- **Session Log Entry** — recent activity feed (US-037)

## Interactions

- Create a learning plan for a stated goal, e.g. a certification, via `/learning-plan` (US-034).
- Check off milestones as they're completed (US-035).
- Plan pacing adapts automatically based on quiz and flashcard performance data (US-036).
- Receive a weekly progress summary of learning and retention (US-037).

## Navigation

- Accessible from: Setup Wizard's initial goal-setting step, or `/learning-plan` at any time.
- Links to: Quiz Generator & Runner, Graded Projects, Flashcard Decks & Review, Session Log Viewer.
