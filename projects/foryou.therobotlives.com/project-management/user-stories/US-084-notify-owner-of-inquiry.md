---
id: US-084
title: "Notify the site owner of a new inquiry"
slug: notify-owner-of-inquiry
personas: [P-003, P-005]
epic: "Inquiries & Lead Capture"
priority: should-have
complexity: low
tags: [inquiry, notification, owner]
---

# US-084: Notify the site owner of a new inquiry

## User Story

**As a** site owner
**I want to** be notified when a new inquiry arrives
**So that** I can follow up promptly

## Acceptance Criteria

- **Given** a new inquiry is submitted
  **When** it is recorded
  **Then** the site owner receives a notification with the inquiry details
- **Given** a Service has a configured notification recipient
  **When** an inquiry arrives for it
  **Then** the notification goes to that recipient
- **Given** notification delivery fails
  **When** it errors
  **Then** the inquiry is still stored and the failure is logged

## Notes
