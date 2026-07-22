---
id: US-096
title: "Configure CORS for cross-origin signups"
slug: cors-configuration
personas: [P-003, P-006]
epic: "Infrastructure"
priority: must-have
complexity: medium
tags: [infra, cors, cross-origin, security]
---

# US-096: Configure CORS for cross-origin signups

## User Story

**As a** platform operator
**I want to** CORS configured to allow portfolio-domain origins on the public endpoint
**So that** the embeddable widget submits successfully cross-origin

## Acceptance Criteria

- **Given** an allowed portfolio origin
  **When** it sends a preflight to the public signup endpoint
  **Then** CORS responds permitting the request
- **Given** a disallowed origin
  **When** it attempts a request
  **Then** CORS blocks it
- **Given** the allow-list changes
  **When** a Service maps a new domain (US-018)
  **Then** its origin is permitted without a redeploy where feasible

## Notes
Recon current mechanism in `endpoint.ex`/`config/runtime.exs` (plan Chunk A).
Getting CORS wrong makes every external widget signup 4xx.
