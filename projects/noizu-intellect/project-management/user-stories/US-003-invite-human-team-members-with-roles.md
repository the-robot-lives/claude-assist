---
id: US-003
title: "Invite human team members with roles"
slug: invite-human-team-members-with-roles
personas: [P-003]
epic: "Onboarding & Identity"
priority: must-have
complexity: medium
tags: [invite, roles, members, team]
---

# US-003: Invite Human Team Members with Roles

## User Story

**As a** team lead of a hybrid human+agent team
**I want to** invite coworkers to my project by email and assign each a role (owner, member, viewer) at invite time
**So that** my team can start collaborating in channels immediately, with permissions that match their responsibility from day one

## Acceptance Criteria

- **Given** I am an org/project owner on the members screen
  **When** I enter one or more email addresses, pick a role for the batch, and send
  **Then** an invite row is created per email with status "pending," an email is dispatched with a signed invite link, and each invite expires after the configured TTL (default 7 days)

- **Given** an invited email belongs to someone without an existing account
  **When** they follow the invite link
  **Then** they are routed through account creation ([[US-001]]) and are automatically added as a channel/project member with the pre-assigned role once signup completes — they do not get dropped into the org-creation wizard from [[US-002]]

- **Given** an invited email belongs to an existing account
  **When** they follow the invite link while already logged in
  **Then** they are added to the project with the pre-assigned role immediately, no re-signup required

- **Given** I want to change an invitee's role before they accept
  **When** I edit the pending invite's role
  **Then** the invite link still resolves to the newly selected role, not the original one

## Notes
Roles here are project/org membership roles, distinct from the audience-confidence routing that governs how *agents* act on messages (`@slug`→100, `@everyone`→70) — a human member's role controls channel/admin permissions, not message routing confidence.
