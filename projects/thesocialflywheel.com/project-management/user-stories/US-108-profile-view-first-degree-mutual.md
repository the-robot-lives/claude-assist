---
id: US-108
title: "Profile view for a 1st-degree mutual"
slug: profile-view-first-degree-mutual
personas: [P-003]
epic: "Profile & Identity"
priority: must-have
complexity: medium
tags: [profile, privacy, mutuals]
---

# US-108: Profile View for a 1st-Degree Mutual

## User Story

**As a** social connector
**I want** my 1st-degree mutuals (moots) to see my full profile
**So that** people I have directly connected with get the complete picture and can engage fully

## Acceptance Criteria

- **Given** another user is a confirmed 1st-degree mutual of mine
  **When** they view my profile
  **Then** they see my full profile including bio, banner, links, interests, and mutual-lane context

- **Given** that mutual connection is later removed
  **When** they view my profile again
  **Then** their access drops to the appropriate further-degree or stranger view

## Notes
First-degree is the highest-trust visibility tier; closer degrees rank higher in any shared surfaces.
