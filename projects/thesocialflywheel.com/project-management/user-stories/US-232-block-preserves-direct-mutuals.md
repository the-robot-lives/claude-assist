---
id: US-232
title: "Block Preserves Direct Mutuals"
slug: block-preserves-direct-mutuals
personas: [P-004]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: medium
tags: [safety, block, graph]
---

# US-232: Block Preserves Direct Mutuals

## User Story

**As a** Cautious Newcomer (P-004)
**I want to** block someone without losing my direct mutual connections to people who also know that person
**So that** blocking a bad actor does not damage my existing trusted relationships

## Acceptance Criteria

- **Given** I block User B who is a mutual of my 1st-degree mutual User A
  **When** the block is applied
  **Then** User A remains my 1st-degree mutual and their posts continue to appear normally in my feed

- **Given** I block User B with cascade enabled
  **When** the cascade resolves
  **Then** users for whom I have a direct (1st-degree) connection are unaffected by the cascade — only outer-degree-only paths through User B are removed

## Notes
The system must differentiate "reachable only via blocked user" from "also reachable via another direct path." Direct mutual status always wins.
