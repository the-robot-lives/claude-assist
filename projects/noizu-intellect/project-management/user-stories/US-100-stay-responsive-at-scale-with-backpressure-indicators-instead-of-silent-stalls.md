---
id: US-100
title: "Stay responsive at scale with backpressure indicators instead of silent stalls"
slug: stay-responsive-at-scale-with-backpressure-indicators-instead-of-silent-stalls
personas: [P-001, P-006]
epic: "Edge Cases, Errors, Performance & Accessibility"
priority: should-have
complexity: high
tags: [performance, backpressure, scale, oban, quotas]
---

# US-100: Stay Responsive at Scale With Backpressure Indicators Instead of Silent Stalls

## User Story

**As a** solo staff engineer (Devon Reyes) running many concurrent parallel paths and agents at once
**I want to** see explicit backpressure indicators when the system is queuing or throttling work under load
**So that** the UI stays responsive and I understand why a path is waiting, instead of it appearing frozen with no explanation

## Acceptance Criteria

- **Given** the Oban queues (ingestion, path-execution, memory) are at or near capacity
  **When** a new turn or path is queued behind existing work
  **Then** the UI shows a visible "queued" state with an estimated position or wait indicator, rather than showing nothing until the turn suddenly starts

- **Given** a large number of concurrent paths/agents (e.g. dozens of paths across multiple active runs)
  **When** the system is under load
  **Then** channel and run views remain interactively responsive (scrolling, filtering, opening a path) even while background execution is throttled, because UI rendering is decoupled from execution throughput

- **Given** a per-project or per-org quota/budget limit is approached during a run
  **When** paths would exceed it
  **Then** the system surfaces a backpressure/quota warning before silently queuing indefinitely or hard-failing without explanation

- **Given** an admin (Nadia Volkov) monitoring overall system load
  **When** viewing queue/agent health
  **Then** backpressure state (queue depth, throttled paths, quota proximity) is visible in an admin dashboard, not only inferred from individual run UIs

## Notes
Complements [[US-095]] and [[US-096]] — those cover failure recovery, this covers graceful degradation under legitimate load rather than failure. Backpressure indicators should reuse the run status filtering from [[US-086]] so "queued/throttled" is a first-class filterable state.
