---
id: US-054
title: "Email and Password Login"
slug: email-password-login
personas: [P-004]
epic: "Authentication & Security"
priority: must-have
complexity: low
tags: [login, password, email]
---

# US-054: Email and Password Login

## User Story

**As a** cautious newcomer
**I want to** log in with my email and password
**So that** I can access my account securely without relying on third-party services

## Acceptance Criteria

- **Given** I have a verified account
  **When** I submit correct credentials
  **Then** I am logged in and see my home feed within 2 seconds

- **Given** I submit incorrect credentials
  **When** the attempt fails
  **Then** I see a generic "invalid email or password" message and my remaining attempts are not disclosed
