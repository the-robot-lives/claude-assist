---
id: US-839
title: "No-Results State Offers Alternative Suggestions"
slug: no-results-with-suggestions
personas: [P-008]
epic: "Search & Find"
priority: should-have
complexity: medium
tags: [search, empty-state, suggestions, UX]
---

# US-839: No-Results State Offers Alternative Suggestions

## User Story

**As a** accessibility-first user
**I want to** see the no-results state proactively suggest alternatives
**So that** I don't reach a dead end and know how to proceed

## Acceptance Criteria

- **Given** a search returns no results
  **When** the empty state renders
  **Then** it suggests: widening the degree filter, checking spelling, or exploring the Discovery lane — each as a distinct actionable link

- **Given** typo tolerance found a close match
  **When** no exact results exist
  **Then** "Did you mean X?" appears above the empty state message with a clickable correction

## Notes
All suggestion controls must be keyboard-reachable and screen-reader announced as part of the results region.
