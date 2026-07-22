---
id: US-097
title: "Configure the transactional mailer"
slug: transactional-mailer
personas: [P-003]
epic: "Infrastructure"
priority: must-have
complexity: medium
tags: [infra, mailer, email, deliverability]
---

# US-097: Configure the transactional mailer

## User Story

**As a** platform operator
**I want to** a verified transactional mailer for confirmation and preference emails
**So that** double opt-in and unsubscribe emails actually deliver

## Acceptance Criteria

- **Given** the public flows need email
  **When** a confirmation, resend, or unsubscribe email is triggered
  **Then** it is delivered via the configured mailer
- **Given** per-Service sender identity (US-017)
  **When** email is sent
  **Then** it uses the correct from/reply-to with a safe default fallback
- **Given** a delivery failure
  **When** it occurs
  **Then** it is logged and observable (US-099)

## Notes
Confirm existing mailer (smart_token_email already sends — verify Swoosh config)
per plan Chunk A.
