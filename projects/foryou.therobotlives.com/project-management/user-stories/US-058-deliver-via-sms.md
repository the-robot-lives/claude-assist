---
id: US-058
title: "Deliver messages via SMS"
slug: deliver-via-sms
personas: [P-001]
epic: "Contact Preferences"
priority: wont-have
complexity: high
tags: [delivery, sms, deferred, out-of-scope]
---

# US-058: Deliver messages via SMS

## User Story

**As a** subscriber who chose SMS
**I want to** actually receive messages by text
**So that** I'm reached on my phone

## Acceptance Criteria

- **Given** SMS is an enabled channel preference
  **When** a message is dispatched
  **Then** it is delivered via an SMS provider respecting frequency and quiet periods
- **Given** SMS delivery fails
  **When** the provider errors
  **Then** the failure is recorded and retried per policy
- **Given** a subscriber opts out via SMS reply
  **When** they reply STOP
  **Then** the SMS channel is disabled

## Notes
WON'T-HAVE for M0–M5. Preference is stored now (US-052); the SMS sender is a
later delivery milestone ("beyond listmonk"). Deferred.
