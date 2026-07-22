---
id: US-079
title: "Monitor queue depth and agent process health"
slug: monitor-queue-depth-and-agent-process-health
personas: [P-006]
epic: "Admin & Platform Ops"
priority: must-have
complexity: high
tags: [oban, queues, health, alerts]
---

# US-079: Monitor Queue Depth and Agent Process Health

## User Story

**As a** self-hosting admin/SRE
**I want to** see live queue depth for ingestion, path-execution, and memory Oban queues alongside the up/down status of each agent's GenServer process
**So that** I can catch backlog buildup or a crashed agent process before users notice degraded response times

## Acceptance Criteria

- **Given** the ops dashboard is open
  **When** I view the queue panel
  **Then** I see current depth, oldest-job age, and jobs-per-minute throughput for each of the ingestion, path-execution, and memory queues, refreshed at least every 30 seconds

- **Given** an agent's per-project GenServer process is not running (crashed, not yet started, or supervisor restart-looping)
  **When** I view the agent health panel
  **Then** that agent is flagged down with its last-known state and restart count

- **Given** a queue's oldest-job age or depth crosses a configured threshold
  **When** the threshold is crossed
  **Then** an alert is sent to configured admin recipients, distinct from the token-budget alerts in [[US-077]]

- **Given** an agent process is restart-looping (more than N restarts within a window)
  **When** the threshold is hit
  **Then** the supervisor stops auto-restarting it, marks it degraded, and surfaces a manual-restart action to the admin

## Notes
Backs the "Oban queues (ingestion, path-execution, memory)" and "long-running process per agent per project" mechanics. This is the operational counterpart to the spend reporting in [[US-078]] — one tracks cost, this tracks liveness/throughput.
