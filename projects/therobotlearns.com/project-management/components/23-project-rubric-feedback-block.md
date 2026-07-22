# Project Rubric Feedback Block

| Field | Value |
|-------|-------|
| **ID** | `project-rubric-feedback-block` |
| **Category** | AI-Specific |
| **Used In** | 09-Graded Projects |

## Description

The grader sub-agent's structured evaluation of a submitted project against the assignment's rubric — per-criterion scores plus actionable notes, not just a single grade. Single-use, but included as a complex structured-output pattern distinct from the generic results summary.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Compact** | Overall grade plus criteria pass/fail summary |
| **Expanded** | Full per-criterion breakdown with rationale and suggested fixes |

## Props / Configuration

- `criteria` — array of `{name, score, maxScore, note}`
- `overallGrade`

## Interactions

- Each criterion links to the KB articles the feedback cites, and to a "practice this" action that opens a relevant flashcard deck or quiz.
