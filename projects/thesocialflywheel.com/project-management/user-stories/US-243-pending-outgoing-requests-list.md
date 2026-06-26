---
id: US-243
title: "Pending Outgoing Requests List"
slug: pending-outgoing-requests-list
personas: [P-003]
epic: "Mutuals Graph & Degrees"
priority: should-have
complexity: low
tags: [requests, pending]
---

# US-243: Pending Outgoing Requests List

## User Story

**As a** Social Connector (P-003)
**I want to** view all mutual requests I have sent that are still awaiting a response
**So that** I can track my outreach and cancel any I no longer want to pursue

## Acceptance Criteria

- **Given** I navigate to "Requests" and open the Sent tab
  **When** the list loads
  **Then** each pending outgoing request shows the recipient's name, avatar, when the request was sent, and a "Cancel" button

- **Given** a recipient accepts my request while I am viewing the Sent tab
  **When** the connection is established
  **Then** that entry moves out of the Sent list and a brief "Now mutual with [name]" indicator replaces it

## Notes
Requests older than 30 days (or platform-configured TTL) may auto-expire; expired requests should appear with an "Expired" badge rather than a Cancel button.
