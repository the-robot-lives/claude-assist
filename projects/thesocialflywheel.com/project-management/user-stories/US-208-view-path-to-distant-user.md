---
id: US-208
title: "View Path to Distant User"
slug: view-path-to-distant-user
personas: [P-001]
epic: "Mutuals Graph & Degrees"
priority: could-have
complexity: high
tags: [graph, degrees, discovery]
---

# US-208: View Path to Distant User

## User Story

**As a** Bridge-Builder (P-001)
**I want to** see the chain of mutual connections between myself and a 3rd or 4th-degree user
**So that** I understand how we are connected and who might introduce us

## Acceptance Criteria

- **Given** I view the profile of a 3rd or 4th-degree user
  **When** I tap "See how you're connected"
  **Then** the app displays a path (e.g., You → Alice → Bob → Them) showing each intermediate mutual

- **Given** multiple shortest paths exist
  **When** the path is displayed
  **Then** one representative shortest path is shown, with an option to see "X more paths"

- **Given** intermediate users have set their profiles to private
  **When** the path is rendered
  **Then** those users appear as "A mutual of [name]" without exposing their display name or avatar

## Notes
Path computation should be capped at 4 hops. Paths involving blocked users must be excluded entirely.
