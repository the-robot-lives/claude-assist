---
id: US-821
title: "Typo Tolerance in Channel Search"
slug: typo-tolerance-channel-search
personas: [P-002]
epic: "Search & Find"
priority: should-have
complexity: medium
tags: [search, typo-tolerance, fuzzy, channels]
---

# US-821: Typo Tolerance in Channel Search

## User Story

**As a** niche enthusiast
**I want to** have channel search tolerate minor typos
**So that** I find the right channel even when I misspell its name

## Acceptance Criteria

- **Given** I search "scienc" instead of "science"
  **When** results appear
  **Then** channels containing "science" are returned along with a "Did you mean: science?" suggestion

- **Given** the corrected query suggestion is shown
  **When** I click it
  **Then** the search reruns with the corrected spelling and original filters intact

## Notes
Typo tolerance should handle transpositions, missing letters, and common phonetic substitutions.
