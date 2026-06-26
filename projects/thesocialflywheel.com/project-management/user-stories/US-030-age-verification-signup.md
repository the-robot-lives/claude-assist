---
id: US-030
title: "Age Verification During Signup"
slug: age-verification-signup
personas: [P-004, P-010]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: low
tags: [age-verification, compliance, signup, safety]
---

# US-030: Age Verification During Signup

## User Story

**As a** new user
**I want to** enter my date of birth during signup
**So that** the platform can confirm I meet the minimum age requirement

## Acceptance Criteria

- **Given** I am on the age verification step
  **When** I enter a date of birth that makes me under 16
  **Then** I see a message that I do not meet the age requirement and signup is halted.

- **Given** I am 16 or older
  **When** I enter my date of birth and continue
  **Then** I proceed to the next step with my age recorded (not displayed publicly by default).

## Notes
Date of birth is stored encrypted and not shown on public profiles by default. Jurisdiction-based minimum age rules may raise the threshold — implement a configurable rule per region. COPPA/GDPR-K compliance required.
