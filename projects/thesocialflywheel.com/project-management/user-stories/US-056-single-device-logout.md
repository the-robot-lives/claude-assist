---
id: US-056
title: "Single Device Logout"
slug: single-device-logout
personas: [P-004]
epic: "Authentication & Security"
priority: must-have
complexity: low
tags: [logout, session, security]
---

# US-056: Single Device Logout

## User Story

**As a** cautious newcomer
**I want to** log out of the current device with one click
**So that** others who use this device cannot access my account

## Acceptance Criteria

- **Given** I am logged in
  **When** I click "Log out" from the account menu
  **Then** my session is invalidated, all local tokens are cleared, and I am redirected to the login page

- **Given** I am logged out
  **When** I press the browser back button
  **Then** I am not able to return to authenticated pages without logging in again
