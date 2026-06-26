---
id: US-240
title: "Mutual Count on Profile"
slug: mutual-count-on-profile
personas: [P-003]
epic: "Mutuals Graph & Degrees"
priority: should-have
complexity: low
tags: [profile, graph, stats]
---

# US-240: Mutual Count on Profile

## User Story

**As a** Social Connector (P-003)
**I want to** see my total 1st-degree mutual count displayed on my public profile
**So that** visitors can quickly gauge my network size and social activity on the platform

## Acceptance Criteria

- **Given** I view my own profile
  **When** the profile header loads
  **Then** a "Mutuals" count shows the number of my 1st-degree mutual connections, tappable to open the full mutuals list

- **Given** I view another user's profile
  **When** the header loads
  **Then** I see their mutual count, subject to their privacy setting (may be hidden if they set it to private)

## Notes
Only 1st-degree count is shown publicly by default. Users can opt out of displaying this count in their privacy settings.
