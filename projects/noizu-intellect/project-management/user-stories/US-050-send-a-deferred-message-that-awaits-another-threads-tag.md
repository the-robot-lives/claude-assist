---
id: US-050
title: "Send a deferred message that awaits another thread's tagged completion"
slug: send-a-deferred-message-that-awaits-another-threads-tag
personas: [P-001, P-003]
epic: "Parallel-Path Execution"
priority: could-have
complexity: high
tags: [deferred-message, lambda, cross-thread, tag]
---

# US-050: Send a Deferred Message That Awaits Another Thread's Tagged Completion

## User Story

**As a** team lead running hybrid human+agent workflows
**I want to** compose a message now that only delivers once a different thread reaches a specific tag (e.g. another path's completion tag)
**So that** I can set up cross-path or cross-thread dependencies — "notify the integration path once path B finishes" — without polling or manually watching the other thread

## Acceptance Criteria

- **Given** I am composing a message in thread A
  **When** I set it as deferred and target a tag name expected on thread B (which may not exist yet)
  **Then** the message is stored in a pending/lambda state, not delivered, and is visible in thread A's history as "awaiting: thread B / tag X"

- **Given** a deferred message is pending on a not-yet-created tag
  **When** thread B later creates a tag with that exact name (manually via US-042, or automatically at path completion via US-051)
  **Then** the deferred message is delivered into thread A's live stream and durable inbox at that moment, addressed and audience-routed as if freshly sent

- **Given** multiple deferred messages target the same tag
  **When** the tag is created
  **Then** all of them deliver, in the order they were originally composed, and each is independently marked delivered so none re-fires on a later re-tag attempt (tag names are unique per thread, so this is a single-fire trigger)

- **Given** a deferred message's target thread is deleted or the run is cancelled before the tag ever appears
  **When** that happens
  **Then** the deferred message is marked "unresolved" rather than silently disappearing, and remains visible to the sender for cleanup

## Notes
This is the mechanism that lets Sam's team wire up delegation across concurrent paths ("ping me when the fastest path finishes") without a human babysitting the live view. It composes directly with tags (US-042) and path completion (US-051) as trigger sources — no new checkpoint primitive is introduced.
