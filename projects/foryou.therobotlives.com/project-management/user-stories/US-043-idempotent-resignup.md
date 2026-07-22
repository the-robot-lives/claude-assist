---
id: US-043
title: "Re-signup idempotently without duplicates"
slug: idempotent-resignup
personas: [P-001]
epic: "Signups & Subscriptions"
priority: should-have
complexity: medium
tags: [signup, idempotent, upsert, dedupe]
---

# US-043: Re-signup idempotently without duplicates

## User Story

**As a** subscriber who signs up again with the same email
**I want to** avoid creating duplicate entries
**So that** I'm not contacted multiple times for one list

## Acceptance Criteria

- **Given** I already signed up to a List
  **When** I submit the same email again
  **Then** my existing signup is updated (upsert), not duplicated
- **Given** I previously unsubscribed
  **When** I sign up again
  **Then** my status is re-activated per the List's opt-in mode
- **Given** an upsert occurs
  **When** attribute values differ
  **Then** the latest submitted values are stored

## Notes
Enforced by a unique (list_id, lower(email)) constraint.
