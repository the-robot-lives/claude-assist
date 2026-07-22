# Error & Recovery Notices

| Field | Value |
|-------|-------|
| **ID** | `error-and-recovery-notices` |
| **Type** | Modal |
| **Category** | Resilience & Errors |
| **User Stories** | US-082, US-084, US-085, US-086, US-087 |

## Description

Not a destination screen — an inline notice pattern that can interrupt any other screen when the KB's data integrity or environment is at risk. Covers corrupted-file quarantine, a missing/unreachable Claude Code backend, write-safety guarantees, concurrent-session protection, and launcher/template version drift.

## Key Components

- **Error/Warning Banner** — the notice itself (US-082, US-084, US-087)
- **Confirmation Prompt** — guided resolution steps (US-086)

## Interactions

- An unparseable YAML file is automatically quarantined with a clear explanation rather than crashing the session (US-082).
- A clear, actionable error appears when Claude Code (the backend) is unreachable or auth has expired (US-084).
- Disk-full or an interrupted write is guaranteed to never corrupt an existing KB file — atomic writes only (US-085).
- A second concurrent session against the same KB is blocked by a lockfile guard instead of silently clobbering the first (US-086).
- A launcher-vs-template version mismatch is surfaced with guided resolution steps instead of a confusing downstream error (US-087).

## Navigation

- Accessible from: any screen, whenever the corresponding failure condition triggers.
- Links to: back to the screen that was interrupted, once the condition is resolved.
