---
id: US-616
title: "View Full Exclusion List"
slug: view-full-exclusion-list
personas: [P-001]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: low
tags: [safety, management]
---

# US-616: View Full Exclusion List

## User Story

**As a** bridge-builder
**I want to** view a complete list of all interest and belief tags I have excluded
**So that** I know exactly what content is being filtered from my experience

## Acceptance Criteria

- **Given** I navigate to Settings > Safety > Excluded Interests
  **When** the page loads
  **Then** I see all excluded tags with the date added and which lanes each exclusion applies to

- **Given** I have excluded both interest tags and belief tags
  **When** I view the exclusion list
  **Then** the two categories are visually grouped or filterable

## Notes
Complements the block list (US-615); these are separate lists in the UI.
