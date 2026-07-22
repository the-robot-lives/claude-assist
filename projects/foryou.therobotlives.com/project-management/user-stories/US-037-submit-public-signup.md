---
id: US-037
title: "Submit a public signup form"
slug: submit-public-signup
personas: [P-001, P-007]
epic: "Signups & Subscriptions"
priority: must-have
complexity: medium
tags: [signup, public, form, unauth]
---

# US-037: Submit a public signup form

## User Story

**As a** visitor on a portfolio site
**I want to** sign up to a List by submitting its public form
**So that** I join the list and start receiving what I asked for

## Acceptance Criteria

- **Given** a public List form
  **When** I submit valid values for its attributes
  **Then** my signup is recorded and I receive a generic success acknowledgment
- **Given** I submit without authenticating
  **When** the request is accepted
  **Then** no login is required to sign up
- **Given** the List uses double opt-in
  **When** I submit
  **Then** I am told to check my email to confirm (US-040)

## Notes
Endpoint: `POST /api/v1/public/services/:svc/lists/:list/signups`. Must be
keyboard- and screen-reader-accessible and usable on low bandwidth.
