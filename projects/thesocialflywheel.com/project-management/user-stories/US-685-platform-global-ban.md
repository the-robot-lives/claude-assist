---
id: US-685
title: "Platform Global Ban"
slug: platform-global-ban
personas: [P-007]
epic: "Moderation & Reporting"
priority: must-have
complexity: high
tags: [platform-trust-safety, global-ban, sanctions]
---

# US-685: Platform Global Ban

## User Story

**As a** platform Trust & Safety reviewer
**I want to** apply a global ban that removes a user's access to the entire platform
**So that** users who commit severe violations (CSAM, credible threats, coordinated harassment) cannot simply move to a new channel

## Acceptance Criteria

- **Given** I am a platform T&S reviewer with global-ban authority
  **When** I apply a global ban to a user account with a stated reason and policy citation
  **Then** the user's session is terminated, all active sessions are invalidated, and they cannot log in from any device

- **Given** a global ban is applied
  **When** the banned user attempts to access the platform
  **Then** they see a "Your account has been permanently suspended" screen with the policy reason and a link to the appeal process

- **Given** a global ban is in effect
  **When** affected channel mods check their member lists
  **Then** the banned user appears in the "Banned" section with "Platform ban — T&S" as the reason, without exposing the underlying case details

## Notes
Global bans must require two-person sign-off (or a 1-hour cooling-off period) for reviewers below senior T&S level.
