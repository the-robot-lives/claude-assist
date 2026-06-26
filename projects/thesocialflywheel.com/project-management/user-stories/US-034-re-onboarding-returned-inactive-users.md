---
id: US-034
title: "Re-onboarding for Returned Inactive Users"
slug: re-onboarding-returned-inactive-users
personas: [P-010, P-006]
epic: "Onboarding & Account Setup"
priority: should-have
complexity: medium
tags: [re-onboarding, inactive, returning-user, engagement]
---

# US-034: Re-onboarding for Returned Inactive Users

## User Story

**As a** returning user who has been inactive for over 90 days
**I want to** a brief re-onboarding experience that shows me what has changed and prompts me to refresh my interests
**So that** I re-engage with the platform feeling up to date

## Acceptance Criteria

- **Given** I have not logged in for 90+ days
  **When** I log in
  **Then** I see a "Welcome back" screen listing top new features and offering an "Update my interests" shortcut.

- **Given** I choose to update interests
  **When** I complete the interest update flow
  **Then** my feed refreshes immediately with new channel recommendations.

## Notes
Do not show the full onboarding tutorial again — only the delta. Allow dismissal with one tap. Trigger re-onboarding at most once per 90-day inactive period.
