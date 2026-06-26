---
id: US-242
title: "Pending Incoming Requests List"
slug: pending-incoming-requests-list
personas: [P-003]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: low
tags: [requests, pending]
---

# US-242: Pending Incoming Requests List

## User Story

**As a** Social Connector (P-003)
**I want to** view all my pending incoming mutual requests in one place
**So that** I can review and action them at my own pace rather than one at a time from notifications

## Acceptance Criteria

- **Given** I navigate to "Requests" in the app
  **When** the Incoming tab loads
  **Then** I see a list of all pending incoming mutual requests, each showing the requester's name, avatar, mutual count in common, and Accept/Decline actions

- **Given** I have no pending incoming requests
  **When** the Incoming tab loads
  **Then** an empty state illustration and message "No pending requests" is shown

## Notes
The request list should update in real time if a requester cancels their request while the list is open.
