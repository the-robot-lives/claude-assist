---
id: US-054
persona: P-004
persona_slug: trd-reverse-engineer
title: "Lift bytecode toward readable source"
epic: "Code round-trip & LLM codegen"
priority: P1
segment: secondary
tags: [reverse-compile, decompiled-source, readability, round-trip]
---

# US-054 — Lift bytecode toward readable source

**As** Sven, the reverse engineer,
**I want** view a decompiled element's lifted, readable source alongside its bubble,
**so that** I can read the recovered logic without leaving the model.

## Acceptance criteria
- [ ] Selecting a decompiled node shows its lifted source in a syntax-highlighted viewer
- [ ] The viewer indicates this is decompiler output, with confidence/quality caveats where applicable
- [ ] Long output is fully copyable even when the on-screen view is truncated, and truncation is clearly indicated
- [ ] Elements with no recoverable body show a clear 'no source recovered' state

## Notes
Serves the README 'reverse compile' capability; counters UX-review P2 silent code-viewer truncation.
