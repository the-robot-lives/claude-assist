---
id: US-503
title: "First Message Request to New Mutual"
slug: first-message-request-to-new-mutual
personas: [P-001]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: medium
tags: [direct-messages, message-request, new-mutuals, onboarding]
---

# US-503: First Message Request to New Mutual

## User Story

**As a** Bridge-Builder (P-001)
**I want to** send a first message to a newly confirmed mutual that is held as a message request until they accept
**So that** both sides feel comfortable before a full DM thread is opened

## Acceptance Criteria

- **Given** a mutual relationship was just established (within the last 24 hours)
  **When** I send a first message
  **Then** it is delivered as a message request the recipient must accept or decline before a full thread opens

- **Given** the recipient declines my message request
  **When** the declination is processed
  **Then** no thread is created, I am not notified of the decline (to prevent retaliation), and I cannot send another request for 7 days

- **Given** the recipient accepts my message request
  **When** they tap "Accept"
  **Then** the full DM thread opens for both parties and subsequent messages are delivered immediately

## Notes
After the first exchange is accepted, future messages in the same thread are not held as requests.
