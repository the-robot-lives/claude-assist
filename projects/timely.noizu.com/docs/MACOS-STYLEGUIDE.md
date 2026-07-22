# Timely macOS Style Guide

Timely is a workbench for evidence-backed time tracking. The interface should feel dense, calm, and inspectable. Empty space is used to separate workflows, not to leave core actions off-screen.

## Design Principles

- **Capture first:** the active task, project, start/pause/resume/stop actions, and screenshot action must be visible from Today and Capture.
- **Evidence is paired with interpretation:** screenshots and Vision LLM observations appear together so users can audit AI claims.
- **Privacy stays explicit:** local-only storage, retention, and notification controls are plain settings, not hidden preferences.
- **Desktop-native density:** use sidebars, tables, compact cards, and toolbar commands. Avoid sparse mobile-style pages.
- **AI is transparent:** show model, confidence, inferred project/task, and error states. Never present AI analysis as fact without confidence.

## Visual System

| Token | Value | Usage |
| --- | --- | --- |
| Accent | `#D61F73` | Primary actions, active navigation, AI project labels |
| Success | `#1AA352` | Running capture, enabled states, billable/valid indicators |
| Warning | `#C77A1A` | Paused state, likely project switch |
| Danger | `#C72424` | Errors and destructive actions |
| Radius | `8px` | Cards, list rows, thumbnails |
| Button radius | `6px` | Primary and secondary buttons |
| Spacing | 8px base | 12px compact groups, 16px cards, 24px page padding |

Typography uses SF Pro through SwiftUI system fonts. Page titles use semibold 30pt; card titles use headline; metadata uses caption with secondary text.

## Layout

The main shell is a `NavigationSplitView` with these destinations:

- Today
- Capture
- Manual Entry
- Timeline
- Evidence
- Vision LLM
- Pomodoro
- Settings

Screens use a constrained work area, usually 1040-1360px wide. Dashboards use a four-column metric grid followed by two-column operational panels. Tables and lists sit directly on the page in a single card, not inside nested cards.

## Components

- **Primary button:** filled accent, one primary action per panel.
- **Secondary button:** neutral surface with subtle border for alternate commands.
- **Status pill:** icon, label, and semantic color; never color alone.
- **Metric tile:** icon, label, large value, short detail.
- **Evidence row:** thumbnail, screenshot metadata, AI status, inferred project, switch badge, reveal action.
- **Empty state:** compact neutral row with concrete next step.

## Screen Rules

- **Today:** must show current span status, metrics, task controls, latest AI status, recent spans, and evidence summary.
- **Capture:** must show task/project fields and all live controls above policy details.
- **Manual Entry:** must show title, project/client, start, end, billable state, notes, and add action.
- **Timeline:** must use a table for spans with title/project, start/end, duration, source, billable, and delete.
- **Evidence:** must show screenshots with thumbnails and paired analysis.
- **Vision LLM:** must expose provider, model, base URL, API key or `env: NAME`, prompt, confidence threshold, manual analysis, and recent results.
- **Settings:** must expose screenshot interval, local-only mode, Pomodoro durations, storage paths, and retention. Retention supports `Forever`.

## Accessibility

- Do not rely on color alone; every state uses text and an SF Symbol.
- Keep button labels verb-first and concrete.
- Keep table columns and form labels visible.
- Preserve keyboard navigation through native SwiftUI controls.
- Keep text at fixed semantic sizes; do not scale type based on viewport width.
