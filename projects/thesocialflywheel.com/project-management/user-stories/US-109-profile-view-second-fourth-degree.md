---
id: US-109
title: "Profile view for a 2nd–4th-degree viewer"
slug: profile-view-second-fourth-degree
personas: [P-006]
epic: "Profile & Identity"
priority: should-have
complexity: medium
tags: [profile, privacy, mutuals]
---

# US-109: Profile View for a 2nd–4th-Degree Viewer

## User Story

**As a** quiet consumer
**I want** viewers who are 2nd–4th-degree mutuals to see a partial profile of me
**So that** I can be discoverable through my network without exposing everything to near-strangers

## Acceptance Criteria

- **Given** a viewer is connected to me at 2nd–4th degree via the mutuals graph
  **When** they view my profile
  **Then** they see a reduced view (e.g. avatar, name, pronouns, interest tags) with full bio and links gated

- **Given** the shortest connection degree changes (e.g. from 3rd to 1st)
  **When** they next view my profile
  **Then** the visible detail updates to match their new, closer degree

## Notes
Degree is computed as the shortest mutuals path, capped at 4th for discovery.
