---
id: US-973
title: "Register Webhooks for Mutual Events"
slug: register-webhooks-for-mutual-events
personas: [P-003]
epic: "Insights, Analytics & Integrations"
priority: could-have
complexity: medium
tags: [api, webhooks, developer, mutuals]
---

# US-973: Register Webhooks for Mutual Events

## User Story

**As a** Social Connector
**I want to** register a webhook that fires when I gain or lose a mutual
**So that** I can keep external CRM or contact tools in sync with my Flywheel social graph automatically.

## Acceptance Criteria

- **Given** a registered webhook with the mutual.added event selected
  **When** a new mutual relationship is established
  **Then** a signed JSON payload with the event type and timestamp (but not the other user's identity) is delivered to my URL within 60 seconds.

- **Given** a registered webhook with the mutual.removed event selected
  **When** a mutual relationship ends
  **Then** a signed payload with event type and timestamp is delivered.

## Notes

Other user's identity is never included in webhook payloads; only aggregate metadata and timestamps are delivered. Webhook owner can correlate via their own Flywheel account if needed.
