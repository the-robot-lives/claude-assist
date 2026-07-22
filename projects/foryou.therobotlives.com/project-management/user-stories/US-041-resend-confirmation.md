---
id: US-041
title: "Resend a confirmation email"
slug: resend-confirmation
personas: [P-001]
epic: "Signups & Subscriptions"
priority: should-have
complexity: low
tags: [signup, double-opt-in, email, resend]
---

# US-041: Resend a confirmation email

## User Story

**As a** subscriber who didn't get or lost the confirmation email
**I want to** request it again
**So that** I can complete my subscription

## Acceptance Criteria

- **Given** my signup is still `pending_optin`
  **When** I request a resend
  **Then** a fresh tokenized confirmation email is sent and prior tokens are invalidated
- **Given** I request resends repeatedly
  **When** I exceed the allowed rate
  **Then** further resends are throttled
- **Given** my signup is already `subscribed`
  **When** I request a resend
  **Then** I am told no confirmation is needed

## Notes
