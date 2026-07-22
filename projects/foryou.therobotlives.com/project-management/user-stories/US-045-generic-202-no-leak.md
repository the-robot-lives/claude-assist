---
id: US-045
title: "Return a generic response that never leaks membership"
slug: generic-202-no-leak
personas: [P-008, P-001]
epic: "Signups & Subscriptions"
priority: must-have
complexity: medium
tags: [signup, security, privacy, no-leak]
---

# US-045: Return a generic response that never leaks membership

## User Story

**As a** platform defending against enumeration
**I want to** the public endpoint to respond identically regardless of prior membership
**So that** attackers cannot probe who is already on a list

## Acceptance Criteria

- **Given** an email already on a List
  **When** a signup is submitted for it
  **Then** the response is an identical generic 202, revealing nothing
- **Given** a brand-new email
  **When** a signup is submitted
  **Then** the response is the same generic 202
- **Given** any submission
  **When** it is processed
  **Then** timing and body do not distinguish existing from new members

## Notes
Pairs with rate-limiting (US-100) and double opt-in (US-040).
