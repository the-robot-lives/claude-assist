---
id: US-039
title: "Validate signups on client and server"
slug: validate-signup
personas: [P-001, P-008]
epic: "Signups & Subscriptions"
priority: must-have
complexity: medium
tags: [signup, validation, security]
---

# US-039: Validate signups on client and server

## User Story

**As a** list owner
**I want to** signups validated against the List's attribute rules
**So that** stored data is well-formed and safe

## Acceptance Criteria

- **Given** a submission with an invalid value
  **When** it is checked
  **Then** it is rejected with field-level errors on the client and re-validated on the server
- **Given** a submission with extra or unknown fields
  **When** the server processes it
  **Then** unknown fields are ignored and payload size is bounded
- **Given** required attributes are missing
  **When** the server validates
  **Then** the submission is rejected regardless of client state

## Notes
Server-side validation is authoritative; never trust the client.
