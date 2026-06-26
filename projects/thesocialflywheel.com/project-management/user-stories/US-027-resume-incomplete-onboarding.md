---
id: US-027
title: "Resume Incomplete Onboarding on Return"
slug: resume-incomplete-onboarding
personas: [P-004, P-010, P-006]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: medium
tags: [resume, onboarding, persistence, returning-user]
---

# US-027: Resume Incomplete Onboarding on Return

## User Story

**As a** user who left the app mid-onboarding
**I want to** the app to remember where I stopped
**So that** I do not have to repeat steps I already completed

## Acceptance Criteria

- **Given** I completed steps 1–3 of onboarding and then closed the app
  **When** I reopen the app
  **Then** I am presented with step 4 with steps 1–3 marked complete.

- **Given** my session token has expired between sessions
  **When** I return, When I log in
  **Then** my partial onboarding state is restored from the server.

## Notes
Persist onboarding progress server-side, not only in local storage. Progress state should sync across devices.
