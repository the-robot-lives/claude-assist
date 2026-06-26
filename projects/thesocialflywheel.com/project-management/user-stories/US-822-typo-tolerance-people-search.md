---
id: US-822
title: "Typo Tolerance in People Search"
slug: typo-tolerance-people-search
personas: [P-003]
epic: "Search & Find"
priority: should-have
complexity: medium
tags: [search, typo-tolerance, fuzzy, people]
---

# US-822: Typo Tolerance in People Search

## User Story

**As a** social connector
**I want to** have people search tolerate name misspellings
**So that** I find the right person even if I'm unsure of the exact spelling

## Acceptance Criteria

- **Given** I search "Jonathon" when the user's name is "Jonathan"
  **When** results appear
  **Then** the correct user is returned with a relevance score reflecting the near-match

- **Given** a typo-corrected result appears
  **When** I view the person card
  **Then** a subtle "Close match" indicator is shown so I know the match was fuzzy

## Notes
Fuzzy matching applies to display names and handles; exact matches always rank first.
