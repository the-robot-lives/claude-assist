---
id: US-949
title: "Real-User Performance Monitoring Dashboard"
slug: performance-monitoring-dashboard
personas: [P-009]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: medium
tags: [monitoring, rum, performance, observability, dashboard]
---

# US-949: Real-User Performance Monitoring Dashboard

## User Story

**As a** creator who wants to ensure my content loads quickly for my audience
**I want** the platform engineering team to have real-user monitoring (RUM) data available in an operations dashboard
**So that** performance regressions affecting content load and viewer experience are detected and fixed quickly

## Acceptance Criteria

- **Given** a user interacts with the app in production
  **When** core web vital metrics are captured (LCP, INP, CLS, TTFB)
  **Then** they are sent to the RUM service within 30 seconds and available in the dashboard within 5 minutes

- **Given** LCP p75 exceeds 4 seconds for any feed route over a 5-minute window
  **When** the threshold is breached
  **Then** an automated alert fires to the on-call engineer channel

## Notes
Use `web-vitals` JS library for metric capture. Sample 10% of sessions. Break down metrics by device class, connection type, and route. Alert thresholds: LCP > 4 s, INP > 500 ms, CLS > 0.25.
