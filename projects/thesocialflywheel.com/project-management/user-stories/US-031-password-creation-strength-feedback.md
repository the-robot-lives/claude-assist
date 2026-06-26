---
id: US-031
title: "Password Creation and Strength Feedback"
slug: password-creation-strength-feedback
personas: [P-004, P-010]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: low
tags: [password, security, signup]
---

# US-031: Password Creation and Strength Feedback

## User Story

**As a** new user
**I want to** real-time feedback on my password strength
**So that** I can create a secure password without guessing the rules

## Acceptance Criteria

- **Given** I am typing a password
  **When** each character is entered
  **Then** a strength indicator (weak / fair / strong) updates in real time with a brief explanation of what is missing.

- **Given** I submit a password below "fair"
  **When** I tap continue
  **Then** I see an inline error explaining the minimum requirements (length, digit, special char).

## Notes
Use zxcvbn or equivalent entropy-based scoring — not just rule-based. Never show raw entropy score to the user; translate to the three-level label. "Show password" toggle required.
