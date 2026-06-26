---
id: US-841
title: "Accessible Search Filter Controls"
slug: accessible-search-filter-controls
personas: [P-008]
epic: "Search & Find"
priority: must-have
complexity: medium
tags: [search, filters, accessibility, ARIA, keyboard]
---

# US-841: Accessible Search Filter Controls

## User Story

**As a** accessibility-first user
**I want to** operate all search filter controls using only the keyboard and a screen reader
**So that** I can refine searches without needing a mouse

## Acceptance Criteria

- **Given** the filter panel is open
  **When** I use Tab to navigate
  **Then** every filter control (dropdowns, date pickers, checkboxes) is reachable and operable via keyboard

- **Given** a filter chip is active
  **When** I navigate to it with a screen reader
  **Then** the reader announces the filter name and "press Delete to remove"

## Notes
Custom dropdown controls must implement the ARIA combobox or listbox pattern per WCAG 2.1 AA.
