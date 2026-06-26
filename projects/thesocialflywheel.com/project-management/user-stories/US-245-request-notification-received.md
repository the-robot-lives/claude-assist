---
id: US-245
title: "Request Notification Received"
slug: request-notification-received
personas: [P-004]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: low
tags: [requests, notifications]
---

# US-245: Request Notification Received

## User Story

**As a** Cautious Newcomer (P-004)
**I want to** receive a notification when someone sends me a mutual request
**So that** I am aware of incoming requests and can review them on my own timeline

## Acceptance Criteria

- **Given** another user sends me a mutual request
  **When** the request is created
  **Then** I receive an in-app notification and, if enabled, a push notification reading "[Name] sent you a mutual request"

- **Given** I tap the notification
  **When** it opens
  **Then** I am taken directly to the requester's profile where I can Accept, Decline, or view their info before deciding

- **Given** I have notifications muted for mutual requests
  **When** a request arrives
  **Then** no push notification is sent; the request still appears in my in-app Requests list with a badge count
