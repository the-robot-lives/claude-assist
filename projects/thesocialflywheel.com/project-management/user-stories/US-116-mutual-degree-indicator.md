---
id: US-116
title: "See mutual degree indicator on a profile"
slug: mutual-degree-indicator
personas: [P-001]
epic: "Profile & Identity"
priority: must-have
complexity: low
tags: [profile, moots, identity]
---

# US-116: See Mutual Degree Indicator On A Profile

## User Story

**As a** bridge-builder
**I want to** see how many degrees of separation I have from another user
**So that** I understand how closely we are connected in the moots graph

## Acceptance Criteria

- **Given** I view another user's profile
  **When** they fall within my ≤4th-degree mutuals
  **Then** the profile shows the degree (1st..4th) connecting us

- **Given** the user is beyond 4th degree or unconnected
  **When** I view their profile
  **Then** no degree indicator is shown

## Notes
Degree reflects the shortest symmetric mutuals path between the two users.
