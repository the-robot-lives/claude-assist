# Timely macOS App

SwiftUI-first scaffold for Timely's desktop capture agent.

Current capabilities:

- Start, pause, resume, and stop an active time span.
- Enter manual time spans with title, project/client, start, end, billable flag, and notes.
- View tracked spans in a table with start, end, duration, source, and billable state.
- Start Pomodoro focus spans with configurable focus and break durations.
- Capture screenshots on demand.
- Enable periodic screenshot capture while a timer or Pomodoro focus span is active.
- View screenshot records with thumbnails and reveal captured files in Finder.
- Configure Vision LLM analysis for periodic screenshots, including provider, model, base URL, API key or `env: NAME`, prompt, confidence threshold, and project-switch notifications.
- Analyze the latest screenshot on demand and review AI status updates, inferred task/project, confidence, and error states.
- Persist spans, screenshot records, and settings under `~/Library/Application Support/Timely/`.
- Menu bar extra for quick status, pause/resume, stop, and screenshot capture.
- Settings scene for screenshot interval, periodic capture, local-only mode, forever/timed retention, and Pomodoro timing.

Visible use-case navigation:

| Sidebar Item | Use Case |
|--------------|----------|
| Today | Shows live status, metrics, capture controls, latest AI status, recent spans, and evidence summary. |
| Capture | Name a task, optionally name a project/client, start/pause/resume/stop live tracking, and capture an on-demand screenshot. |
| Manual Entry | Enter a completed time span manually with title, project/client, start/end, billable flag, and notes. |
| Timeline | Inspect and delete recorded spans. |
| Evidence | Capture now, view screenshot records, review AI observations, reveal screenshot files, and open the screenshot folder. |
| Vision LLM | Configure screenshot analysis and project-switch detection. |
| Pomodoro | Start a Pomodoro focus span and manage focus/break timers. |
| Settings | Enable periodic screenshots and configure screenshot interval, forever/timed retention, local-only storage, and Pomodoro durations. |

Design reference:

- [../../docs/MACOS-STYLEGUIDE.md](../../docs/MACOS-STYLEGUIDE.md)

Build check:

```bash
swift build
```

This Swift Package is a developer scaffold. The current app is unsigned and local-first. macOS may require Screen Recording permission before screenshots succeed.
