# Query & Answer

| Field | Value |
|-------|-------|
| **ID** | `query-and-answer` |
| **Type** | Primary |
| **Category** | Calibrated Q&A |
| **User Stories** | US-001, US-002, US-003, US-004, US-005, US-006, US-007, US-010, US-017, US-018, US-054, US-069, US-090, US-094 |

## Description

The core interaction surface of the product — the terminal output of the `/knowledge-base-query` (`/query`) slash command. A user asks a question in natural language; the agent answers it calibrated to their per-domain expertise level and machine profile, then silently saves the answer as a new knowledge article. This is where most users spend most of their time, and where the product's core promise — "answers calibrated to your expertise" — is delivered.

## Key Components

- **Calibrated Answer Block** — the depth-adjusted answer itself (US-001, US-002)
- **Related Topics Chips** — adjacent-topic suggestions after the answer (US-006)
- **Expertise Level Badge** — shows the domain/level driving the current calibration (US-002)
- **Machine/Environment Profile Card** — ambient context grounding the answer in the user's real toolchain (US-003)
- **Verbosity/Depth Slider** — one-off beginner/verbosity override (US-017, US-054)

## Interactions

- User runs `robot-learns <question>` or invokes `/query` inside an active session; the agent streams a calibrated answer to the terminal.
- Follow-up questions reuse session context without re-explaining what was already asked (US-010).
- A one-off override (e.g. `--beginner`) simplifies a single answer without changing the stored profile (US-017, US-054).
- Compare/contrast questions ("X vs Y") are recognized and saved as a structured comparison article instead of a plain Q&A note (US-018).
- The answer is auto-saved as a KB article and cross-linked to related existing articles the moment the response completes (US-004, US-005, US-007).
- Content renders in the user's preferred language when one is set (US-090); underlying agent calls are kept minimal by design (US-094).

## Navigation

- Accessible from: Setup Wizard's welcome tour points here first; otherwise the primary entry point any time via the `robot-learns` CLI or `/query`.
- Links to: Knowledge Article Viewer (once the answer is saved), KB Browse & Search, Learning Plan Dashboard (when a query surfaces a tracked knowledge gap).
