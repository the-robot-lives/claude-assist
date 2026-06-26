---
id: US-201
title: "Send Mutual Request"
slug: send-mutual-request
personas: [P-003]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: low
tags: [graph, requests]
---

# US-201: Send Mutual Request

## User Story

**As a** Social Connector (P-003)
**I want to** send a mutual request to another user from their profile or a post
**So that** I can grow my mutuals web and gain access to their full post stream

## Acceptance Criteria

- **Given** I am viewing another user's profile or a post authored by them
  **When** I tap "Add Mutual"
  **Then** a pending mutual request is created and the button changes to "Request Sent"

- **Given** the target user already has mutual requests disabled in their privacy settings
  **When** I attempt to send a mutual request
  **Then** the option is hidden or disabled with a brief explanation

## Notes
Request state must persist across sessions so the sender sees "Request Sent" consistently until accepted, declined, or cancelled.
