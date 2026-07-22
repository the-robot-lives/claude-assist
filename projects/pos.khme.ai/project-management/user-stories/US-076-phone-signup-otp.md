---
id: US-076
title: "Phone-number signup + OTP"
slug: "phone-signup-otp"
personas: [P-001, P-002]
epic: "Onboarding & Setup"
priority: "must-have"
complexity: "M"
tags: [onboarding, auth, otp]
---

# US-076: Phone-number signup + OTP

## User Story

**As a** market-stall owner (P-001),
**I want to** sign up using just my phone number and a one-time code,
**So that** I can start using the app without needing an email address or complex passwords.

## Acceptance Criteria

- [ ] Given a new user opens the app for the first time, when they enter a valid Cambodian phone number, then an OTP is sent via SMS within 30 seconds.
- [ ] Given the user receives the OTP, when they enter the correct 6-digit code within the validity window, then their account is created and they are signed in.
- [ ] Given the user enters an incorrect OTP three times, when they attempt a fourth time, then the app locks OTP entry for 5 minutes and offers a "resend code" option.

## Notes

No password required in v1 — phone number is the primary identifier. SMS delivery reliability in rural areas should be monitored; a backup channel is out of scope for v1. Depends on: nothing. Related: US-077 (store setup follows signup).
