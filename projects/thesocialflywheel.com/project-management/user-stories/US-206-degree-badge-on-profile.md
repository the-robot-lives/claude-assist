---
id: US-206
title: "Degree Badge on Profile"
slug: degree-badge-on-profile
personas: [P-001]
epic: "Mutuals Graph & Degrees"
priority: should-have
complexity: low
tags: [graph, degrees, profile]
---

# US-206: Degree Badge on Profile

## User Story

**As a** Bridge-Builder (P-001)
**I want to** see a compact degree badge displayed on user profiles and in user lists
**So that** I can quickly assess connection proximity without navigating to a full profile

## Acceptance Criteria

- **Given** I view a profile card or inline user mention
  **When** the user is within my 4th-degree web
  **Then** a small "1st", "2nd", "3rd", or "4th" badge appears adjacent to their display name

- **Given** the user is my 1st-degree mutual
  **When** the badge renders
  **Then** it uses a visually distinct style (e.g., filled color) to differentiate direct connections from outer degrees

## Notes
Badge must include an accessible label (e.g., aria-label="1st-degree mutual") so screen readers can announce it correctly.
