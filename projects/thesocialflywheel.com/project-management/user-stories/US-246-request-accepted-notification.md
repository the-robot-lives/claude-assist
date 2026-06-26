---
id: US-246
title: "Request Accepted Notification"
slug: request-accepted-notification
personas: [P-003]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: low
tags: [requests, notifications]
---

# US-246: Request Accepted Notification

## User Story

**As a** Social Connector (P-003)
**I want to** be notified when someone accepts my mutual request
**So that** I know the connection is live and can start engaging with their content

## Acceptance Criteria

- **Given** a user I sent a request to accepts it
  **When** the acceptance is processed
  **Then** I receive an in-app notification and, if push is enabled, a push notification reading "[Name] accepted your mutual request — you're now connected!"

- **Given** I tap the acceptance notification
  **When** it opens
  **Then** I am taken to the new mutual's profile, showing the "1st" degree badge and the option to browse their posts

## Notes
This notification closes the loop on the request flow and reinforces the social reward of mutual formation. Keep copy warm and celebratory in tone.
