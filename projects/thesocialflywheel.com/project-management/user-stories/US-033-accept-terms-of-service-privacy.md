---
id: US-033
title: "Accept Terms of Service and Privacy Policy"
slug: accept-terms-of-service-privacy
personas: [P-004, P-006, P-010]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: low
tags: [legal, terms, privacy, compliance]
---

# US-033: Accept Terms of Service and Privacy Policy

## User Story

**As a** new user
**I want to** clearly see and accept the Terms of Service and Privacy Policy before creating my account
**So that** I understand what I am agreeing to

## Acceptance Criteria

- **Given** I am on the account creation step
  **When** I reach the ToS screen
  **Then** I see a summary of key points and inline links to the full ToS and Privacy Policy documents.

- **Given** I do not check the acceptance checkbox
  **When** I tap "Create account"
  **Then** the button stays disabled and a tooltip explains acceptance is required.

## Notes
Separate checkboxes for ToS and marketing communications (marketing is opt-in, not bundled). Record timestamp and version of ToS accepted. Present again if ToS version updates.
