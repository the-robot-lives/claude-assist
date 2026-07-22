---
id: US-002
title: "Register and log in with email"
slug: register-and-login
personas: [P-001, P-002]
epic: "Onboarding & Auth"
priority: must-have
complexity: medium
tags: [auth, registration, login]
---

# US-002: Register and log in with email

## User Story

**As a** new user
**I want to** create an account and log in with my email
**So that** I can manage my subscriptions and preferences

## Acceptance Criteria

- **Given** I am on the register screen
  **When** I submit a valid email and credentials
  **Then** my account is created and I am signed in
- **Given** I already have an account
  **When** I enter valid login credentials
  **Then** I am authenticated and taken to `/app`
- **Given** I enter an email that already exists on registration
  **When** I submit
  **Then** I am guided to sign in instead, without leaking whether the account exists beyond a generic prompt

## Notes
On register, reconcile any prior anonymous signups sharing this email (US-050).
