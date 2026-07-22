# Timely macOS App

SwiftUI-first scaffold for Timely's desktop capture agent.

Current capabilities:

- Main window with sidebar dashboard, timeline, evidence, and privacy sections.
- Menu bar extra for current capture state, pause/resume, prompt count, and screenshot interval.
- Settings scene for screenshot interval, local-only storage, retention, and excluded apps.
- Shared in-memory model for capture state, policy, and intervals.

Build check:

```bash
swift build
```

This Swift Package is a developer scaffold. Packaging as a signed `.app` bundle, screen recording permission checks, active-window metadata, screenshot capture, and notarization are next implementation steps.

