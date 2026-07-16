# Profile Manager

| Field | Value |
|-------|-------|
| **ID** | `profile-manager` |
| **Type** | Settings |
| **Category** | Onboarding & Setup |
| **User Stories** | US-047, US-048 |

## Description

Manages the lifecycle of named profiles (e.g. a "work" stack vs. a "personal-learning" stack) and clean uninstallation — distinct from the first-run wizard, which only creates the first profile.

## Key Components

- **Profile Selector** — list and switch profiles (US-047)
- **Confirmation Prompt** — uninstall guard (US-048)
- **Expertise Level Badge** — per-profile domain summary (US-047)

## Interactions

- Maintain multiple named profiles and switch between them, each with its own expertise levels, learning style, and KB (US-047).
- Cleanly uninstall `robot-learns` while preserving or exporting KB data (US-048).

## Navigation

- Accessible from: Settings & Preferences, or Setup Wizard during a re-run.
- Links to: Setup Wizard (re-run for a new profile), Settings & Preferences.
