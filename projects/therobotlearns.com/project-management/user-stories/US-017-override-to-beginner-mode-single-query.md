---
id: US-017
title: "Override to Beginner Mode for a Single Query"
slug: override-to-beginner-mode-single-query
personas: [P-005, P-002]
epic: "Knowledge Base"
priority: should-have
complexity: low
tags: [override, beginner-mode, query]
---

# US-017: Override to Beginner Mode for a Single Query

## User Story

**As a** career-switcher still building fluency
**I want to** request a one-off beginner-mode override on a single query
**So that** I can get a simpler explanation without permanently changing my profile's calibration

## Acceptance Criteria

- **Given** my profile is calibrated above beginner level for a domain
  **When** I pass a beginner-mode flag to `/query`
  **Then** that single answer is delivered at beginner depth regardless of my profile setting

- **Given** I use the beginner-mode override
  **When** the query completes
  **Then** my underlying user profile expertise level is left unchanged

- **Given** the resulting article is saved
  **When** I browse it later
  **Then** it is marked as having been answered in beginner-mode so I know the depth may be shallower than my profile default

## Notes
None.
