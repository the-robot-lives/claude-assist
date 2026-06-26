---
id: US-972
title: "Register Webhooks for Post Events"
slug: register-webhooks-for-post-events
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: should-have
complexity: high
tags: [api, webhooks, developer, posts]
---

# US-972: Register Webhooks for Post Events

## User Story

**As a** Creator
**I want to** register a webhook URL to receive HTTP callbacks when my posts are published, reach a new degree, or cross a viral threshold
**So that** I can react to content events in real time in my own tools.

## Acceptance Criteria

- **Given** the Developer Settings page
  **When** I add a webhook URL and select events (post.published, post.reached_degree, post.viral_threshold)
  **Then** Flywheel sends a POST request with a signed JSON payload to my URL within 30 seconds of each event.

- **Given** a webhook delivery that fails (non-2xx response)
  **When** the failure occurs
  **Then** Flywheel retries up to 3 times with exponential backoff and marks the webhook "degraded" after 3 consecutive failures.

- **Given** a registered webhook
  **When** I click "Test"
  **Then** a sample payload is sent immediately to my URL so I can verify the endpoint is receiving correctly.

## Notes

Payloads are signed with HMAC-SHA256 using a per-webhook secret. Users must verify signatures. Webhook delivery logs are retained for 7 days.
