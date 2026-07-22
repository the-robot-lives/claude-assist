# Settings & Preferences

| Field | Value |
|-------|-------|
| **ID** | `settings-and-preferences` |
| **Type** | Settings |
| **Category** | Settings & Preferences |
| **User Stories** | US-049, US-050, US-051, US-053, US-055 |

## Description

Ongoing configuration: expertise levels, learning style, local preferences (editor, pager, output width), review cadence/card limits, and the telemetry opt-in disclosure. Mostly a structured YAML file (`local-preference.yaml`) with a guided terminal editor over it.

## Key Components

- **Expertise Level Badge** — editable per-domain levels (US-049)
- **Verbosity/Depth Slider** — default learning-style verbosity (US-050)
- **Machine/Environment Profile Card** — editor/pager settings (US-051)
- **Theme Picker** — default Quiz SPA theme (US-053)

## Interactions

- Edit per-domain expertise levels at any time as skill grows (US-049).
- Set learning-style preferences — examples-first vs. theory-first, verbosity (US-050).
- Configure local preferences (editor, pager, output width) through the schema-backed YAML file (US-051).
- Set review cadence and daily flashcard limits to match available time (US-053).
- Telemetry is opt-in and its scope is clearly disclosed before enabling (US-055).

## Navigation

- Accessible from: `/setup preferences`, or Profile Manager.
- Links to: Profile Manager, Quiz SPA (theme setting takes effect there).
