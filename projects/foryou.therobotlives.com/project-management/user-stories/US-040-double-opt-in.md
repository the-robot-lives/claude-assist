---
id: US-040
title: "Confirm a subscription via double opt-in"
slug: double-opt-in
personas: [P-001, P-008]
epic: "Signups & Subscriptions"
priority: must-have
complexity: medium
tags: [signup, double-opt-in, email, compliance]
---

# US-040: Confirm a subscription via double opt-in

## User Story

**As a** subscriber to a newsletter-style list
**I want to** confirm my subscription by clicking a link in an email
**So that** only I can subscribe my address and I'm protected from list-bombing

## Acceptance Criteria

- **Given** I sign up to a double-opt-in List
  **When** my signup is recorded
  **Then** its status is `pending_optin` and a confirmation email with a tokenized link is sent
- **Given** I open the confirmation link
  **When** the token is valid and unexpired
  **Then** my status becomes `subscribed`
- **Given** the token is invalid, expired, or reused
  **When** I open it
  **Then** confirmation fails safely and I can request a new one (US-041)

## Notes
MANDATORY. Double opt-in defends against email-bombing third parties (P-008).
Single opt-in is allowed for waitlist/contact lists per List setting (US-024).
