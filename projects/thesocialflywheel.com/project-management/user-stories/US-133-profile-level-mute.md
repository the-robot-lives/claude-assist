---
id: US-133
title: "Profile-level mute without blocking"
slug: profile-level-mute
personas: [P-006]
epic: "Profile & Identity"
priority: should-have
complexity: medium
tags: [profile, privacy, safety]
---

# US-133: Profile-Level Mute Without Blocking

## User Story

**As a** quiet consumer
**I want to** mute a profile so I stop seeing its activity
**So that** I can reduce noise without the social friction of blocking someone

## Acceptance Criteria

- **Given** I mute a profile
  **When** that user posts or appears in a feed or discovery lane
  **Then** their content is suppressed from my view while our mutual relationship is unchanged

- **Given** I have muted a profile
  **When** the muted user views the interaction
  **Then** they receive no notification or indication that they were muted

## Notes
Mute is one-directional and silent, distinct from block (which severs visibility both ways).
