---
id: US-001
title: "Email Signup Registration"
slug: email-signup-registration
personas: [P-004, P-010]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: low
tags: [signup, email, authentication]
---

# US-001: Email Signup Registration

## User Story

**As a** cautious newcomer
**I want to** sign up with my email address and a password
**So that** I can create an account without linking my social media profiles

## Acceptance Criteria

- **Given** I am on the signup page
  **When** I enter a valid email and a password meeting strength requirements and submit
  **Then** my account is created and I receive a verification email.

- **Given** I enter an email already registered
  **When** I submit
  **Then** I see a clear error prompting me to log in or recover my account instead.

## Notes
Password must be ≥ 10 chars with at least one digit and one special character. Duplicate-email error must not reveal whether the existing account used social login.
