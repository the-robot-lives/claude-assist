# Setup Wizard

| Field | Value |
|-------|-------|
| **ID** | `setup-wizard` |
| **Type** | Storyboard |
| **Category** | Onboarding & Setup |
| **User Stories** | US-039, US-040, US-041, US-042, US-043, US-044, US-045, US-046, US-092 |

## Description

The multi-step first-run flow: install, bootstrap the agent environment, detect the machine profile, build a user profile, seed starter KB content, and tour the six slash commands. Also the entry point for a safe re-run later without destroying existing data.

## Key Components

- **Setup Step Indicator** — progress through the flow (US-040)
- **Profile Selector** — name this profile (US-041)
- **Machine/Environment Profile Card** — detected OS/tools for confirmation (US-042)
- **Progress Bar / Milestone Tracker** — starter-content seeding progress (US-045)
- **Error/Warning Banner** — missing prerequisite notice (US-043)
- **Confirmation Prompt** — re-run guard (US-044)

## Interactions

- Install globally via npm and launch with a single `robot-learns` command (US-039).
- First run bootstraps `~/.config/the-robot-learns-kb/` from the bundled template via `/setup` (US-040).
- Guided prompts collect per-domain expertise levels and learning-style preferences (US-041).
- Auto-detected OS/tools/versions are shown for confirmation before being written to the machine profile (US-042).
- If Claude Code isn't installed, the wizard detects it and walks through install and authentication (US-043).
- Re-running setup never destroys existing KB data — it's explicitly guarded (US-044).
- Offer starter topics to seed the KB so it isn't empty on day one (US-045).
- A short welcome tour introduces the six slash commands at the end (US-046).
- Cold-start time is kept fast even as the bootstrap does real work (US-092).

## Navigation

- Accessible from: the first `robot-learns` invocation, or explicitly via `/setup` any time after.
- Links to: Query & Answer, Profile Manager, Learning Plan Dashboard.
