---
id: US-042
title: "Unsubscribe via a tokenized link"
slug: unsubscribe-via-token
personas: [P-001]
epic: "Signups & Subscriptions"
priority: must-have
complexity: low
tags: [signup, unsubscribe, token, compliance]
---

# US-042: Unsubscribe via a tokenized link

## User Story

**As a** subscriber
**I want to** unsubscribe from a list with one click from a link in an email
**So that** I can stop being contacted without logging in

## Acceptance Criteria

- **Given** I receive email from a List
  **When** I click the tokenized unsubscribe link
  **Then** my signup status becomes `unsubscribed` and I see confirmation
- **Given** the unsubscribe token is valid
  **When** it is used
  **Then** no login is required to complete the action
- **Given** the token is invalid or already used
  **When** I open it
  **Then** I see a clear message and my state is unchanged

## Notes
Endpoint: token `GET .../unsubscribe`. Mirrored in the preference center (US-062).
