---
id: US-671
title: "Moderator Roles and Permissions"
slug: moderator-roles-and-permissions
personas: [P-007]
epic: "Moderation & Reporting"
priority: must-have
complexity: medium
tags: [moderation, roles, permissions]
---

# US-671: Moderator Roles and Permissions

## User Story

**As a** channel owner
**I want to** assign granular moderator roles to trusted members
**So that** I can delegate specific responsibilities without granting full mod authority to everyone

## Acceptance Criteria

- **Given** I open Channel Settings > Moderators
  **When** I assign a member the "Junior Moderator" role
  **Then** they can warn and timeout users (up to 24 hours) but cannot ban, escalate to platform T&S, or edit channel rules

- **Given** I assign a member the "Moderator" role
  **When** they act in the channel
  **Then** they can perform all actions including ban, escalate, and edit rules, but cannot revoke the owner role or delete the channel

- **Given** I revoke a mod role from a member
  **When** the revocation is saved
  **Then** all their pending claimed reports return to the unassigned queue and the change is recorded in the audit log

## Notes
Role definitions should be platform-defined for consistency; channels should not be able to create entirely custom role names.
