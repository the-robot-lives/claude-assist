---
id: US-060
title: "Deliver via webhook and physical mail"
slug: deliver-via-webhook-and-physical-mail
personas: [P-001, P-003]
epic: "Contact Preferences"
priority: wont-have
complexity: high
tags: [delivery, webhook, physical-mail, deferred, out-of-scope]
---

# US-060: Deliver via webhook and physical mail

## User Story

**As a** subscriber or integrator who chose webhook or physical mail
**I want to** those channels actually deliver
**So that** downstream systems or postal contact are fulfilled

## Acceptance Criteria

- **Given** webhook is an enabled channel
  **When** a message is dispatched
  **Then** a signed webhook is POSTed to the configured endpoint with retries
- **Given** physical mail is an enabled channel
  **When** a message is dispatched
  **Then** a mail-provider job is created with the postal address
- **Given** either channel fails
  **When** the error occurs
  **Then** it is recorded and surfaced to the operator

## Notes
WON'T-HAVE for M0–M5. Preferences stored now; webhook and physical-mail senders
are later delivery milestones. Deferred.
