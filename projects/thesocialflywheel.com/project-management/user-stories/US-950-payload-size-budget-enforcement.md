---
id: US-950
title: "API Payload Size Budget Enforcement"
slug: payload-size-budget-enforcement
personas: [P-010]
epic: "Performance, Scale & Reliability"
priority: could-have
complexity: medium
tags: [api, payload-size, budget, performance, ci]
---

# US-950: API Payload Size Budget Enforcement

## User Story

**As a** skeptical switcher on a metered data plan
**I want to** have every API response lean and free of unused data fields
**So that** my limited data budget goes toward content I actually see rather than unnecessary payload

## Acceptance Criteria

- **Given** any feed API endpoint is called
  **When** the response is measured
  **Then** the response payload for a page of 20 posts does not exceed 50 KB before compression

- **Given** a developer adds new fields to an API response
  **When** the CI pipeline runs
  **Then** a payload-size regression check fails the build if the endpoint's p95 response size increases by more than 20%

## Notes
Implement sparse fieldsets (`?fields=`) for power consumers. Run payload size benchmarks in CI using mock data fixtures. Log p95 response sizes per endpoint to observability dashboard weekly.
