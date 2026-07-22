---
id: US-010
title: "Accept an organization invitation"
slug: accept-invitation
personas: [P-002, P-004]
epic: "Onboarding & Auth"
priority: should-have
complexity: medium
tags: [org, invite, onboarding, members]
---

# US-010: Accept an organization invitation

## User Story

**As an** invited person
**I want to** accept an invitation
**So that** I gain access to the organization and its Services

## Acceptance Criteria

- **Given** I received an invite link
  **When** I open it and sign in (or register)
  **Then** I am added to the organization with the assigned role
- **Given** the invite is expired or already used
  **When** I open the link
  **Then** I see a clear message and no access is granted
- **Given** I accept while signed into a different account
  **When** the email doesn't match
  **Then** I am prompted to use the invited email

## Notes
