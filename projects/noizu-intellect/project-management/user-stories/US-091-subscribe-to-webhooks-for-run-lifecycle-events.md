---
id: US-091
title: "Subscribe to webhooks for run lifecycle events"
slug: subscribe-to-webhooks-for-run-lifecycle-events
personas: [P-005, P-006]
epic: "Integration & API"
priority: should-have
complexity: medium
tags: [webhooks, events, integrations]
---

# US-091: Subscribe to Webhooks for Run Lifecycle Events

## User Story

**As a** researcher working API-first
**I want to** register a webhook URL that receives events for path completed, review ready, and pick made
**So that** my external tooling reacts to run progress in real time instead of polling [[US-090]]'s status endpoint

## Acceptance Criteria

- **Given** I register a webhook with a target URL and a set of event types (path.completed, review.ready, pick.made)
  **When** I save the subscription
  **Then** it is scoped to a project, persisted, and a test ping event is sent immediately to verify the endpoint is reachable

- **Given** a subscribed event occurs during a run (e.g. a path finishes execution)
  **When** the event fires
  **Then** a signed POST is delivered to the webhook URL with a payload containing the event type, run id, path id (where applicable), and a timestamp, within a bounded delay of the underlying state change

- **Given** a webhook delivery fails (non-2xx response or timeout)
  **When** the failure occurs
  **Then** delivery is retried with exponential backoff up to a configured max attempts, after which the subscription is marked degraded and visible as such to the owner

- **Given** I want to verify payload authenticity
  **When** I receive a webhook delivery
  **Then** the payload includes a signature header I can verify against a shared secret shown at subscription time

## Notes
Event payloads should carry enough identifiers (run id, path id) to round-trip into a [[US-090]] GET for full detail rather than embedding the entire turn history inline. Reuses the same PubSub events the live UI streams from, per the "durable inbox + live PubSub" messaging mechanic.
