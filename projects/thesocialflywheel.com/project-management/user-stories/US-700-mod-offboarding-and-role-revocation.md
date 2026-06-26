---
id: US-700
title: "Mod Offboarding and Role Revocation"
slug: mod-offboarding-and-role-revocation
personas: [P-007]
epic: "Moderation & Reporting"
priority: must-have
complexity: low
tags: [moderation, roles, offboarding]
---

# US-700: Mod Offboarding and Role Revocation

## User Story

**As a** channel owner
**I want to** revoke a moderator's role immediately and cleanly
**So that** a departing or problem mod loses access instantly and their open cases are not abandoned

## Acceptance Criteria

- **Given** I open Channel Settings > Moderators and select "Remove Mod Role" for a team member
  **When** I confirm the revocation
  **Then** their mod permissions are revoked immediately (current session included), the change is recorded in the audit log with my display name and a timestamp, and they receive a system notification that their mod role has ended

- **Given** the revoked mod had in-progress cases assigned to them
  **When** the revocation is saved
  **Then** all their "In Review" reports are automatically returned to the unassigned queue so another mod can pick them up without delay

- **Given** the revoked mod was the channel's only moderator
  **When** revocation is attempted
  **Then** a warning is shown: "You are about to remove the only moderator. The channel owner will handle all reports." — and I must confirm a second time

## Notes
Revocation should be immediate and non-reversible through a simple "undo" — re-assigning the role is a deliberate separate action to prevent accidental reinstatement.
