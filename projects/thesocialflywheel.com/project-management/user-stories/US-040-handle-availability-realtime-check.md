---
id: US-040
title: "Handle Availability Check in Real Time"
slug: handle-availability-realtime-check
personas: [P-004, P-009]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: low
tags: [handle, availability, realtime, UX]
---

# US-040: Handle Availability Check in Real Time

## User Story

**As a** new user
**I want to** instant feedback on handle availability as I type
**So that** I do not fill in an entire form only to learn my chosen name is taken at submission

## Acceptance Criteria

- **Given** I am on the handle selection screen and type a handle
  **When** I pause for 300 ms
  **Then** an availability indicator (available / taken / invalid) appears below the field.

- **Given** my handle is taken
  **When** the indicator appears
  **Then** three algorithmically generated available alternatives based on my input are shown below the indicator.

## Notes
Debounce to 300 ms to avoid hammering the API. Availability check must not expose other users' handles or account information. Reserved/profanity list checked client-side first to reduce unnecessary API calls.
