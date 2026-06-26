---
id: US-228
title: "Keyboard Navigation Graph"
slug: keyboard-navigation-graph
personas: [P-008]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: high
tags: [accessibility, graph, a11y]
---

# US-228: Keyboard Navigation Graph

## User Story

**As an** Accessibility-First user (P-008)
**I want to** navigate the mutuals graph (visual or list view) entirely by keyboard
**So that** I am not excluded from exploring my network connections

## Acceptance Criteria

- **Given** I open the graph view and use only keyboard input
  **When** I press Tab / arrow keys
  **Then** focus moves predictably between nodes (visual) or rows (list), and focus is always visibly indicated

- **Given** I focus a node or list entry and press Enter
  **When** the action triggers
  **Then** the user's mini profile card opens with keyboard-accessible actions (View Profile, Add Mutual)

- **Given** the mini profile card is open
  **When** I press Escape
  **Then** focus returns to the node or list entry that opened it

## Notes
Visual graph view must implement a roving tabindex or aria-activedescendant pattern to avoid a tab-stop explosion on large graphs. Minimum WCAG 2.1 AA conformance required.
