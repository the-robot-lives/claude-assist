# Roleplay Transcript

| Field | Value |
|-------|-------|
| **ID** | `roleplay-transcript` |
| **Category** | AI-Specific |
| **Used In** | 08-Simulation Room |

## Description

The live, turn-by-turn dialogue log of a terminal role-play simulation, distinguishing the agent's in-character lines from out-of-character system prompts and the user's responses. Single-use, but included as a complex, distinct interaction pattern central to the simulation experience.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Compact** | Last few turns visible, with scrollback for the rest |
| **Expanded** | Full transcript with turn timestamps, used as the debrief's reference material |

## Props / Configuration

- `turns` — array of `{speaker, text, timestamp, inCharacter: boolean}`

## Interactions

- Scrolls live during the simulation; becomes a static, searchable log once the debrief begins.
