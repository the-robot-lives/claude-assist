---
id: US-049
title: "Block spam signups with a honeypot"
slug: honeypot-anti-spam
personas: [P-008]
epic: "Signups & Subscriptions"
priority: should-have
complexity: low
tags: [signup, spam, honeypot, security]
---

# US-049: Block spam signups with a honeypot

## User Story

**As a** platform defending public forms
**I want to** silently reject automated spam submissions
**So that** lists stay clean without burdening real users

## Acceptance Criteria

- **Given** a hidden honeypot field
  **When** an automated client fills it
  **Then** the submission is silently rejected without creating a signup
- **Given** a real user
  **When** they leave the honeypot untouched
  **Then** their submission proceeds normally
- **Given** a rejected spam submission
  **When** it is dropped
  **Then** the response is indistinguishable from a normal generic 202

## Notes
Complements rate-limiting (US-100) and double opt-in (US-040).
