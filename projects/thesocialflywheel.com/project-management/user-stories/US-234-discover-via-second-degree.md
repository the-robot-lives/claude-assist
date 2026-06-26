---
id: US-234
title: "Discover via Second Degree"
slug: discover-via-second-degree
personas: [P-001]
epic: "Mutuals Graph & Degrees"
priority: should-have
complexity: medium
tags: [discovery, graph, degrees]
---

# US-234: Discover via Second Degree

## User Story

**As a** Bridge-Builder (P-001)
**I want to** browse a curated list of 2nd-degree users as potential new mutuals
**So that** I can deliberately expand my network through trusted introductions

## Acceptance Criteria

- **Given** I navigate to "Discover" or "People you may know"
  **When** the page loads
  **Then** I see a list of 2nd-degree users, sorted by number of shared 1st-degree mutuals (most in common first)

- **Given** a 2nd-degree user is shown in the discover list
  **When** I view their card
  **Then** I see their mutual-in-common count and a one-tap "Add Mutual" button

## Notes
Discovery suggestions must exclude users I have previously declined or blocked.
