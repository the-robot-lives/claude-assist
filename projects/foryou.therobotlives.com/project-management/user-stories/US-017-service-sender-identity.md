---
id: US-017
title: "Set a Service's sender identity"
slug: service-sender-identity
personas: [P-004, P-003]
epic: "Services & Branding"
priority: should-have
complexity: medium
tags: [service, email, sender, deliverability]
---

# US-017: Set a Service's sender identity

## User Story

**As a** Service editor
**I want to** configure the from-name, from-email, and reply-to for a Service
**So that** confirmation and preference emails come from the right sender

## Acceptance Criteria

- **Given** I edit sender identity
  **When** I set a valid from-name, from-email, and reply-to
  **Then** transactional emails for that Service use them
- **Given** I enter an invalid or unverified sender address
  **When** I save
  **Then** I am warned and delivery falls back to a safe default sender
- **Given** sender identity is unset
  **When** an email is sent
  **Then** a platform default from-address is used

## Notes
Feeds the mailer (US-097) for double opt-in + confirmation email.
