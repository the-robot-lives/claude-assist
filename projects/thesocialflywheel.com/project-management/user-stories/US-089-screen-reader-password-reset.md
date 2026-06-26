---
id: US-089
title: "Screen-Reader Accessible Password Reset"
slug: screen-reader-password-reset
personas: [P-008]
epic: "Authentication & Security"
priority: must-have
complexity: low
tags: [accessibility, password-reset, wcag, a11y]
---

# US-089: Screen-Reader Accessible Password Reset

## User Story

**As an** accessibility-first user
**I want to** complete the password reset flow using a screen reader
**So that** I can recover access without sighted assistance

## Acceptance Criteria

- **Given** I click the password reset link in my email
  **When** the reset page loads
  **Then** focus is placed on the first input, all fields are labeled, password strength feedback is read aloud, and success/error states are announced
