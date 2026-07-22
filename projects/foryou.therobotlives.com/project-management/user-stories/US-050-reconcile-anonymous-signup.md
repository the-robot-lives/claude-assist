---
id: US-050
title: "Reconcile anonymous signups to my account"
slug: reconcile-anonymous-signup
personas: [P-001]
epic: "Signups & Subscriptions"
priority: should-have
complexity: medium
tags: [signup, reconcile, account, identity]
---

# US-050: Reconcile anonymous signups to my account

## User Story

**As a** person who signed up anonymously then created an account
**I want to** my prior signups linked to my account by email
**So that** I can manage them in the preference center

## Acceptance Criteria

- **Given** anonymous signups exist for my email
  **When** I register or log in with that email
  **Then** those signups are linked to my user account
- **Given** signups are linked
  **When** I open the preference center
  **Then** I see all of them (US-061)
- **Given** an email is later verified to a different account
  **When** reconcile runs
  **Then** links are resolved without exposing another person's data

## Notes
MANDATORY. Hook in `Foryou.Users.register` + `Foryou.Auth.SSO.authenticate_sso`
(link signups.email → user_id).
