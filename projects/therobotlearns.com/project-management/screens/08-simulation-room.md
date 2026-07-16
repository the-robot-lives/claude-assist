# Simulation Room

| Field | Value |
|-------|-------|
| **ID** | `simulation-room` |
| **Type** | Primary |
| **Category** | Simulations & Projects |
| **User Stories** | US-030, US-031 |

## Description

A terminal role-play simulation — a scripted, agent-driven scenario (e.g. an incident-response drill or a mock interview) that the user works through interactively, followed by a graded debrief.

## Key Components

- **Roleplay Transcript** — the live, turn-by-turn dialogue log (US-030)
- **Score / Results Summary** — the post-simulation debrief (US-031)

## Interactions

- Run a scripted terminal role-play simulation matched to the user's level and goal (US-030).
- Receive a graded debrief after the simulation ends, covering what went well and what didn't (US-031).

## Navigation

- Accessible from: the `/knowledge-base-simulate` command, or Learning Plan Dashboard when a plan schedules a simulation checkpoint.
- Links to: Graded Projects, Learning Plan Dashboard.
