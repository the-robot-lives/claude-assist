---
id: US-123
title: "Change vanity handle"
slug: change-vanity-handle
personas: [P-003]
epic: "Profile & Identity"
priority: should-have
complexity: medium
tags: [profile, identity, handle]
---

# US-123: Change Vanity Handle

## User Story

**As a** social connector
**I want to** change my vanity handle
**So that** my username reflects how I want to be found and known

## Acceptance Criteria

- **Given** I want a new handle
  **When** I enter a desired handle
  **Then** the system validates uniqueness and format and confirms availability before saving

- **Given** my handle changes
  **When** the change is saved
  **Then** mutuals can still find me and old references resolve to my profile

## Notes
Reserve and case-fold handles to prevent impersonation and collisions.
