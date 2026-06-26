---
id: US-009
title: "Browse Interest Categories"
slug: browse-interest-categories
personas: [P-002, P-001, P-005]
epic: "Onboarding & Account Setup"
priority: should-have
complexity: low
tags: [interests, categories, discovery]
---

# US-009: Browse Interest Categories

## User Story

**As a** niche enthusiast
**I want to** browse interests organized into categories
**So that** I can find specific communities that match my passions beyond the top-level tiles

## Acceptance Criteria

- **Given** I am on the interest selection screen
  **When** I tap a category header (e.g. "Sports")
  **Then** I see a scrollable list of sub-interests within that category.

- **Given** I search for a specific interest by keyword
  **When** results appear
  **Then** I can select directly from search results.

## Notes
Interest search should use fuzzy matching. Empty search results show a "Suggest an interest" link.
