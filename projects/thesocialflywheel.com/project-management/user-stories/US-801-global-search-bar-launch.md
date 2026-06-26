---
id: US-801
title: "Launch Global Search Bar"
slug: global-search-bar-launch
personas: [P-002]
epic: "Search & Find"
priority: must-have
complexity: low
tags: [search, global, navigation]
---

# US-801: Launch Global Search Bar

## User Story

**As a** niche enthusiast
**I want to** open a persistent global search bar from any page
**So that** I can find channels, people, or posts without navigating away

## Acceptance Criteria

- **Given** I am on any page
  **When** I click the search icon or press `/`
  **Then** the global search bar receives focus and a results dropdown opens

- **Given** the search bar is open
  **When** I press Escape
  **Then** it closes and focus returns to the element I was on before

## Notes
The `/` shortcut must not trigger when focus is inside a text input.
