---
id: US-810
title: "Autocomplete Suggestions While Typing"
slug: autocomplete-suggestions-while-typing
personas: [P-002]
epic: "Search & Find"
priority: must-have
complexity: medium
tags: [search, autocomplete, suggestions, UX]
---

# US-810: Autocomplete Suggestions While Typing

## User Story

**As a** niche enthusiast
**I want to** see autocomplete suggestions as I type in the search bar
**So that** I can find channels or topics faster without typing the full name

## Acceptance Criteria

- **Given** I type at least 2 characters
  **When** suggestions are available
  **Then** a dropdown shows up to 8 ranked suggestions (channels, people, interests) within 300 ms

- **Given** suggestions appear
  **When** I press the Down arrow key
  **Then** focus moves into the suggestion list and I can select with Enter

## Notes
Suggestions must respect blocks and visibility rules; blocked users never appear.
