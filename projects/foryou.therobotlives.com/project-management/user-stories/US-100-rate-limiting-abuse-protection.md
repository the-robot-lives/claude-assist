---
id: US-100
title: "Rate-limit and protect the public signup endpoint"
slug: rate-limiting-abuse-protection
personas: [P-008, P-003]
epic: "Infrastructure"
priority: must-have
complexity: medium
tags: [infra, rate-limit, abuse, security]
---

# US-100: Rate-limit and protect the public signup endpoint

## User Story

**As a** platform operator
**I want to** the public signup endpoint rate-limited and abuse-resistant
**So that** floods and enumeration cannot harm real users or third parties

## Acceptance Criteria

- **Given** the public signup endpoint
  **When** requests exceed the configured rate
  **Then** excess requests are throttled/shed with a safe response
- **Given** abusive patterns (bursts, rotating origins)
  **When** they hit the endpoint
  **Then** protections engage without blocking legitimate signups
- **Given** throttling occurs
  **When** it happens
  **Then** it never distinguishes existing from new members (works with US-045)

## Notes
Reuses the `:rate_limited_inquiry` pattern. Works with generic 202 (US-045),
honeypot (US-049), and double opt-in (US-040).
