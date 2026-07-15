---
id: US-052
title: "View the full execution tree of a run"
slug: view-the-full-execution-tree-of-a-run
personas: [P-005, P-008]
epic: "Parallel-Path Execution"
priority: should-have
complexity: high
tags: [execution-tree, forks, turns, statuses, semantic-navigation]
---

# US-052: View the Full Execution Tree of a Run

## User Story

**As a** researcher
**I want to** view the complete execution tree of a run — the base checkpoint, every path forked from it, every turn within each path, and every status transition — both live and after the run finishes
**So that** I can understand exactly how a result was reached and reproduce or audit the reasoning behind it

## Acceptance Criteria

- **Given** a run with N paths, some with intra-path agent hand-offs (US-049) and some with human edits mid-flight
  **When** I open the execution tree view
  **Then** I see a hierarchical structure rooted at the shared base tag, branching into each path, with every turn as a node showing acting agent, pass (Plan/Reply/Reflect), and status

- **Given** the run is still in progress
  **When** I view the tree
  **Then** it updates live as new turns and status transitions occur, consistent with the live progress view (US-046), without requiring a manual refresh

- **Given** I am navigating the tree with a screen reader (NVDA)
  **When** I move through nodes
  **Then** the tree is exposed as a semantic list/tree structure (proper ARIA tree role, labeled nodes) rather than a canvas/diagram-only rendering, so every node is reachable and identifiable by keyboard alone

- **Given** the run has completed
  **When** I revisit the tree later
  **Then** it renders identically from durable storage — same structure, same node detail — with no dependency on the live PubSub session that produced it

## Notes
Serves Elias's need for execution-tree inspection and repeatable experiments, and is the accessibility-critical view for Alex: a purely visual node-graph would exclude him, so the tree/list semantic structure is a hard requirement, not a nice-to-have. This view is the natural home for launching US-053 (re-run a losing path) and US-054 (compare siblings) actions.
