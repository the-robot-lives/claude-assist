# Progress Bar / Milestone Tracker

| Field | Value |
|-------|-------|
| **ID** | `progress-bar-milestone-tracker` |
| **Category** | Feedback & Indicators |
| **Used In** | 06-Quiz Generator & Runner, 10-Learning Plan Dashboard, 11-Setup Wizard, 15-Backup & Restore |

## Description

A generic linear progress indicator reused for anything with discrete steps or a completion percentage: quiz question N of M, onboarding steps, learning-plan milestones, or a running backup/restore.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | `[###.......] 30%` single-line bar |
| **Compact** | Bar plus current step label |
| **Expanded** | Full milestone checklist with completion dates |

## Props / Configuration

- `current`, `total` — step counters
- `label` — current step description
- `checklist` — optional array of `{label, done, date}`

## Interactions

- Updates live as the underlying operation progresses; the expanded view lets milestones be checked off manually where applicable (learning plan only).
