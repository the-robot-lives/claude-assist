---
id: US-141
title: "Profile visit notifications"
slug: profile-visit-notifications
personas: [P-003]
epic: "Profile & Identity"
priority: could-have
complexity: medium
tags: [profile, identity, notifications]
---

# US-141: Profile Visit Notifications

## User Story

**As a** social connector
**I want to** opt in to see who recently viewed my profile
**So that** I can spot new mutuals and reach out before a connection goes cold

## Acceptance Criteria

- **Given** I have opted in to profile visit notifications
  **When** another member views my profile
  **Then** their visit appears in my "who viewed" list with a timestamp

- **Given** I have not opted in
  **When** another member views my profile
  **Then** no visit is recorded and the "who viewed" list stays empty

- **Given** a viewer has disabled their own visit visibility
  **When** they view my profile
  **Then** the visit is shown as anonymous or omitted, respecting their setting

## Notes
Reciprocity matters: a member only sees others' visits while their own visits are visible. Default is opt-out.
