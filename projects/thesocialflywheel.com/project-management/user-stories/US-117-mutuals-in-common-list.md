---
id: US-117
title: "See mutuals in common on a profile"
slug: mutuals-in-common-list
personas: [P-003]
epic: "Profile & Identity"
priority: should-have
complexity: medium
tags: [profile, moots, discovery]
---

# US-117: See Mutuals In Common On A Profile

## User Story

**As a** social connector
**I want to** see the list of mutuals I share with another user
**So that** I can recognize trusted connections and find an introduction path

## Acceptance Criteria

- **Given** I view another user's profile
  **When** we share 1st-degree mutuals
  **Then** a "mutuals in common" list shows those shared connections

- **Given** a shared mutual has blocked me or set their visibility to exclude me
  **When** the list renders
  **Then** that mutual is omitted from the list

## Notes
List should respect each shared mutual's own privacy settings before display.
