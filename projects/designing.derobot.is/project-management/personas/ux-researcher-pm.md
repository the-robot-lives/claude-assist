# Lena Vogt — UX Researcher / PM

**Tagline:** "I need a prototype real enough to test by Thursday, and cheap enough to throw three away."

## Demographics / context
- 38, hybrid PM + UX researcher at a mid-size fintech.
- Runs weekly moderated and unmoderated usability tests on flows-in-progress.
- Not a heavy coder; comfortable with YAML, markdown, and structured text.
- Juggles many small prototype variants for A/B and comprehension testing.

## Goals
- Stand up believable, interactive flows fast to put in front of participants.
- Test multiple variants of a flow without rebuilding each from scratch.
- Capture realistic behavior (real data, real state) so findings are valid.
- Keep prototypes legible to stakeholders and easy to revise after a session.

## Frustrations / pain points with current tools
- Figma prototypes fake interactions; participants notice and it skews results.
- Spinning up variant B means duplicating and hand-editing a whole file.
- Engineers are too expensive to borrow for a disposable test build.
- Hard to share a running prototype with a participant without a full deploy.

## How she'd use TRFI specifically
- Authors test flows in the **text DSL**; clones and tweaks variants by editing a few lines.
- Keeps most of a screen **low-fi** but flips the **scoped toggle** on the one region under study so attention lands there — nearest-toggle-wins lets her spotlight a card while the page stays sketchy.
- Wires an **FSM + API/LLM** path so the flow returns real-looking data and remembers state via the **key-value store** across the session.
- Runs sessions in the **Prototype Player** full-screen and shares the link.
- Revises live between participants based on what she just watched fail.

## Key features she cares about
- **Text DSL** — fast variant creation, diff-friendly, legible.
- **Scoped low-fi/high-fi (nearest wins)** — direct attention to the tested region.
- **FSM + LLM/API + key-value store** — valid, stateful, realistic behavior.
- **Prototype Player** — shareable, full-screen runs for participants.
- **Screens dashboard** — keep many variants organized and labeled.

## Representative quote
> "A prototype that fakes the click teaches me nothing. I need it to actually respond so I can trust what I saw."

## Success looks like
She tests three realistic variants in one week, knows which flow wins from real participant behavior, and revises the prototype between sessions in minutes.
