---
id: US-145
title: "Role badge on profile"
slug: role-badge-on-profile
personas: [P-007]
epic: "Profile & Identity"
priority: should-have
complexity: low
tags: [profile, identity, creator, moderation]
---

# US-145: Role Badge on Profile

## User Story

**As a** channel moderator
**I want to** display a creator or moderator role badge on my profile
**So that** members can recognize my role and trust my actions in the channels I manage

## Acceptance Criteria

- **Given** I hold a moderator or creator role in a channel
  **When** members view my profile
  **Then** the corresponding role badge is shown with the associated channel

- **Given** my role is revoked
  **When** the change takes effect
  **Then** the badge is automatically removed from my profile

## Notes
Badges are system-granted, not self-assigned, to prevent impersonation of roles.
