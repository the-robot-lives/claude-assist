---
id: US-009
title: "Invite a member to my organization"
slug: invite-member
personas: [P-003]
epic: "Onboarding & Auth"
priority: should-have
complexity: medium
tags: [org, invite, members, roles, pbac]
---

# US-009: Invite a member to my organization

## User Story

**As an** organization owner/admin
**I want to** invite a person by email and assign a role
**So that** teammates can help manage Services and lists

## Acceptance Criteria

- **Given** I am an org owner/admin
  **When** I enter an invitee email and choose a role
  **Then** an invitation is created and an invite email is sent
- **Given** an invite already exists for that email
  **When** I invite again
  **Then** the existing invite is re-sent rather than duplicated
- **Given** I lack permission to invite
  **When** I open the members area
  **Then** the invite action is not available to me

## Notes
Roles govern PBAC; Service membership inherits from the org/project.
