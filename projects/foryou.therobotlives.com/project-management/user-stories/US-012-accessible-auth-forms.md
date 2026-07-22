---
id: US-012
title: "Use accessible authentication forms"
slug: accessible-auth-forms
personas: [P-007]
epic: "Onboarding & Auth"
priority: should-have
complexity: medium
tags: [auth, accessibility, a11y, wcag]
---

# US-012: Use accessible authentication forms

## User Story

**As a** screen-reader user
**I want to** complete login and registration by keyboard with announced feedback
**So that** I can access my account without barriers

## Acceptance Criteria

- **Given** I use a screen reader
  **When** I tab through the auth forms
  **Then** every field has a programmatic label and a logical focus order
- **Given** validation fails
  **When** I submit
  **Then** errors are announced via a live region, not conveyed by color alone
- **Given** authentication succeeds or fails
  **When** the result renders
  **Then** the outcome is announced to assistive technology

## Notes
Meets WCAG 2.1 AA. Applies to SSO entry, register, and login.
