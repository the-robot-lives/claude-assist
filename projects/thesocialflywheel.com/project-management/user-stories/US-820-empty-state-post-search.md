---
id: US-820
title: "Empty State for Post Search"
slug: empty-state-post-search
personas: [P-008]
epic: "Search & Find"
priority: should-have
complexity: low
tags: [search, empty-state, posts, UX]
---

# US-820: Empty State for Post Search

## User Story

**As a** accessibility-first user
**I want to** see an informative empty state when post search returns nothing
**So that** I understand whether it's a content gap or a visibility restriction

## Acceptance Criteria

- **Given** I search posts and the result is empty
  **When** the empty state renders
  **Then** it distinguishes between "No posts match your query" and "Results hidden by visibility rules" with appropriate messaging for each

- **Given** the empty state cites visibility rules
  **When** I activate the "Why?" link
  **Then** an accessible tooltip or modal explains which visibility rules are active (e.g., members-only channels excluded)

## Notes
"Why?" dialog must be keyboard-dismissible and focus must return to the trigger element on close.
