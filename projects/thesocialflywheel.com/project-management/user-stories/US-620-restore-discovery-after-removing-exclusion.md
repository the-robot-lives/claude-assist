---
id: US-620
title: "Restore Discovery After Removing Exclusion"
slug: restore-discovery-after-removing-exclusion
personas: [P-002]
epic: "Safety: Blocking & Exclusions"
priority: should-have
complexity: medium
tags: [safety, exclusions, discovery]
---

# US-620: Restore Discovery After Removing Exclusion

## User Story

**As a** niche enthusiast
**I want to** see relevant content resurface in Discovery shortly after I remove an exclusion
**So that** my feed reflects my updated preferences without requiring a full account reset

## Acceptance Criteria

- **Given** I remove the exclusion on tag #Astronomy
  **When** Discovery refreshes (next scheduled or on manual pull-to-refresh)
  **Then** posts tagged #Astronomy that match my interest graph begin appearing

- **Given** the exclusion was active for a long time
  **When** it is removed
  **Then** the recommendation engine does not penalise historic suppression — it treats the tag as freshly discovered

## Notes
Feed re-inclusion may take up to one refresh cycle; a toast confirms "Discovery updated for #Astronomy."
