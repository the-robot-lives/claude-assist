---
id: US-003
title: "Phone Number Signup"
slug: phone-number-signup
personas: [P-004, P-008]
epic: "Onboarding & Account Setup"
priority: should-have
complexity: medium
tags: [signup, phone, sms, authentication]
---

# US-003: Phone Number Signup

## User Story

**As a** cautious newcomer
**I want to** sign up using only my phone number
**So that** I do not need to share my email address to join

## Acceptance Criteria

- **Given** I enter a valid phone number
  **When** I tap "Send code"
  **Then** I receive an SMS OTP within 60 seconds.

- **Given** I enter the correct OTP
  **When** I submit
  **Then** my account is created and I proceed to profile setup.

## Notes
Support international dialing codes. Resend OTP is available after 60 s. Limit to 5 attempts before a cooldown.
