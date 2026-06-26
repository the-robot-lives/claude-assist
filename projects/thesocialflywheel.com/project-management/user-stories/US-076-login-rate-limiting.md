---
id: US-076
title: "Login Rate Limiting"
slug: login-rate-limiting
personas: [P-010]
epic: "Authentication & Security"
priority: must-have
complexity: medium
tags: [rate-limiting, security, brute-force]
---

# US-076: Login Rate Limiting

## User Story

**As a** skeptical switcher
**I want to** know that repeated failed login attempts are throttled
**So that** automated brute-force attacks on my account are impractical

## Acceptance Criteria

- **Given** five failed login attempts occur from the same IP within 10 minutes
  **When** a sixth attempt is made
  **Then** further attempts are delayed with exponential back-off and a CAPTCHA is required

- **Given** rate limiting is active on an IP
  **When** a correct password is entered
  **Then** login is still allowed after CAPTCHA, so legitimate users are not permanently blocked
