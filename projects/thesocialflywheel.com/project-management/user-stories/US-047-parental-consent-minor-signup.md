---
id: US-047
title: "Parental Consent Flow for Minor Signup"
slug: parental-consent-minor-signup
personas: [P-004]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: high
tags: [compliance, parental-consent, minor, safety]
---

# US-047: Parental Consent Flow for Minor Signup

## User Story

**As a** user who is 13–15 years old
**I want to** a guided parental consent flow
**So that** my account can be created with appropriate safety controls after a parent approves

## Acceptance Criteria

- **Given** I enter a date of birth indicating age 13–15
  **When** I complete the age check
  **Then** I am taken to a parental consent flow that sends a consent request to a parent email I provide.

- **Given** my parent approves consent
  **When** the approval is confirmed
  **Then** my account is activated with stricter privacy defaults (mutual requests restricted to confirmed contacts only).

## Notes
Applicable jurisdictions include US (COPPA), EU (GDPR-K per member state). Minimum age gates below 13 halt signup entirely with a clear message. Parental email used only for consent — not for marketing. Consent stored per legal requirements.
