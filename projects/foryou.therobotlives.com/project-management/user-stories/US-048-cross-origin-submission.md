---
id: US-048
title: "Submit signups cross-origin from external sites"
slug: cross-origin-submission
personas: [P-006]
epic: "Signups & Subscriptions"
priority: must-have
complexity: medium
tags: [widget, cors, cross-origin, integration]
---

# US-048: Submit signups cross-origin from external sites

## User Story

**As a** developer whose site is on a different origin
**I want to** the widget's submissions to succeed cross-origin
**So that** external signups don't fail with CORS errors

## Acceptance Criteria

- **Given** a widget on an allowed portfolio origin
  **When** it sends a preflight and POST to the public endpoint
  **Then** CORS permits the request and the signup is accepted
- **Given** a request from a disallowed origin
  **When** it hits the endpoint
  **Then** it is rejected by CORS policy
- **Given** a cross-origin failure
  **When** it occurs
  **Then** the widget surfaces a clear, non-technical error to the visitor

## Notes
Depends on CORS configuration (US-096) and Service domain mapping (US-018).
