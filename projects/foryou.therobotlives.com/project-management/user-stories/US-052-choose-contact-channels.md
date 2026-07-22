---
id: US-052
title: "Choose my contact channels"
slug: choose-contact-channels
personas: [P-001]
epic: "Contact Preferences"
priority: must-have
complexity: medium
tags: [preferences, channels, email, delivery]
---

# US-052: Choose my contact channels

## User Story

**As a** subscriber
**I want to** choose which channels may contact me (email now; sms/push/webhook/mail later)
**So that** I'm reached only where I want to be

## Acceptance Criteria

- **Given** I manage preferences
  **When** I enable or disable the email channel
  **Then** my choice is stored and email delivery respects it
- **Given** non-email channels are shown
  **When** I select them
  **Then** my preference is stored even though delivery on those channels is not yet active
- **Given** a List restricts available channels
  **When** I view options
  **Then** only channels the List offers are selectable

## Notes
Email is the only channel actually delivered in this phase; other channels store
preference only (see US-058/US-059/US-060 won't-have).
