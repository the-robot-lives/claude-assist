---
id: US-086
title: "Accessible Login Form"
slug: accessible-login-form
personas: [P-008]
epic: "Authentication & Security"
priority: must-have
complexity: medium
tags: [accessibility, wcag, login, a11y]
---

# US-086: Accessible Login Form

## User Story

**As an** accessibility-first user
**I want to** complete the login form using only a keyboard and screen reader
**So that** I can authenticate without relying on mouse or pointer input

## Acceptance Criteria

- **Given** I navigate to the login page with a keyboard only
  **When** I tab through the form fields
  **Then** focus order is logical (email → password → submit), all fields have visible labels, and error messages are announced by screen readers

- **Given** login fails due to an error
  **When** the error message is displayed
  **Then** focus moves to the error message and it is announced by assistive technology
