---
id: US-087
title: "Protect the inquiry form from spam"
slug: inquiry-spam-protection
personas: [P-008, P-003]
epic: "Inquiries & Lead Capture"
priority: could-have
complexity: low
tags: [inquiry, spam, security, rate-limit]
---

# US-087: Protect the inquiry form from spam

## User Story

**As a** site owner
**I want to** the inquiry form protected from spam
**So that** I'm not flooded with junk leads

## Acceptance Criteria

- **Given** the inquiry endpoint
  **When** submissions exceed the rate limit
  **Then** excess requests are throttled (reusing the `:rate_limited_inquiry` pattern)
- **Given** a honeypot or spam signal
  **When** it triggers
  **Then** the submission is silently dropped
- **Given** legitimate traffic
  **When** it submits normally
  **Then** it is unaffected by the protections

## Notes
Reuses existing `:rate_limited_inquiry` rate-limit pattern.
