---
id: P-008
name: "Alex Marsh"
slug: alex-marsh
archetype: "Screen-reader developer"
segment: edge-case
tags: [accessibility, screen-reader, keyboard-first, developer]
---

# P-008: Alex Marsh

## Demographics

| Attribute | Value |
|-----------|-------|
| Age | 31 |
| Occupation | Backend developer |
| Location | Portland, OR |
| Tech comfort | High |

## Bio
Alex is blind and works with NVDA and a braille display. They are exactly the target user — a developer who wants to delegate to agent teams — but streaming chat UIs, live-updating trees, and drag-to-compare views are hostile territory unless built deliberately.

## Goals
- Follow multi-agent channel activity without being interrupted by every streamed token
- Navigate the execution tree and outcome comparisons entirely by keyboard
- Get the same information density sighted teammates get from status colors and avatars

## Frustrations
- Live regions that announce every streaming chunk (or nothing at all)
- Tree/graph views with no semantic list equivalent
- Focus loss when messages arrive or paths complete

## Behaviors
- Keyboard-only; heavy use of headings/landmarks navigation
- Prefers digest-style summaries over real-time streams
- Files precise accessibility bugs when tools fall short

## Job to Be Done
> "When agent teams are working and producing outcomes, I want non-visual, keyboard-navigable equivalents of every stream, tree, and comparison, so I can operate the system as effectively as anyone."

## Relationship to Product
Uses the full developer surface (channels, path runs, review) through assistive tech; the canary for WCAG 2.2 AA conformance on streaming and hierarchical UI.

## Scenarios
- **Scenario 1:** Digest mode — Alex switches a busy channel to announce message-complete summaries only, with per-agent verbosity settings.
- **Scenario 2:** Tree walk — Alex traverses a five-path execution tree as a nested list, hearing status, grade, and turn count per node, and picks a winner via keyboard.
