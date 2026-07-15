---
id: US-099
title: "Navigate the execution tree and outcome-picking flow by keyboard as semantic lists"
slug: navigate-the-execution-tree-and-outcome-picking-flow-by-keyboard-as-semantic-lists
personas: [P-008]
epic: "Edge Cases, Errors, Performance & Accessibility"
priority: must-have
complexity: high
tags: [accessibility, keyboard-navigation, execution-tree, outcome-picking]
---

# US-099: Navigate the Execution Tree and Outcome-Picking Flow by Keyboard as Semantic Lists

## User Story

**As a** blind developer using NVDA and keyboard-only input (Alex Marsh)
**I want to** navigate the parallel-path execution tree and the outcome-picking (grade comparison, pick + rationale) flow entirely by keyboard, structured as semantic lists rather than a visual tree/graph
**So that** I can inspect paths and select a winning outcome without relying on a pointer-driven graph visualization I cannot perceive

## Acceptance Criteria

- **Given** a run with N paths forked from checkpoints
  **When** rendered for keyboard/screen-reader access
  **Then** the execution tree is exposed as a nested semantic list (proper heading levels and list markup) reflecting fork lineage, fully traversable with standard list-navigation keys, not only as a canvas/SVG diagram

- **Given** focus on a path item in the list
  **When** the user presses the documented "expand" key
  **Then** that path's turn sequence (Plan/Reply/Reflect) expands inline as a sub-list, keeping keyboard focus at a predictable, announced position

- **Given** the outcome-picking flow comparing graded paths
  **When** navigated by keyboard
  **Then** each path's grade, rubric breakdown, and rationale are reachable as a semantic list item with an accessible "select as winner" action reachable via Tab/Enter, not a drag-and-drop or hover-only control

- **Given** a pick action is confirmed via keyboard
  **When** the pick is submitted
  **Then** an ARIA live-region confirmation announces the winning path and that reward back-propagation has been triggered, so the outcome is confirmed without visual inspection

## Notes
Complements [[US-098]]; together these two stories are the core of P-008's usable path. Should be validated against real execution trees of at least 8-12 paths deep with multiple fork levels, not just trivial 2-path examples, to confirm the list nesting stays comprehensible at scale.
