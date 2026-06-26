---
id: US-602
title: "Exclude Belief Tag from Opposing-Views Lane"
slug: exclude-belief-tag-from-opposing-views-lane
personas: [P-005]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: medium
tags: [safety, exclusions, opposing-views]
---

# US-602: Exclude Belief Tag from Opposing-Views Lane

## User Story

**As a** debate seeker
**I want to** exclude specific belief tags from my Opposing-Views lane
**So that** debates I find harmful or off-limits never surface there even though I enjoy other disagreements

## Acceptance Criteria

- **Given** I have added a belief tag to my exclusion list
  **When** the Opposing-Views lane is populated
  **Then** posts tagged with that belief are withheld even if they would otherwise qualify as opposing content

- **Given** I remove a belief tag from my exclusion list
  **When** the Opposing-Views lane refreshes
  **Then** posts with that tag may appear again

## Notes
Read-only Opposing-Views lane — exclusions prevent surfacing, not merely interaction.
