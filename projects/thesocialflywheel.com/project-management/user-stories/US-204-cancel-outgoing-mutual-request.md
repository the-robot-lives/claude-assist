---
id: US-204
title: "Cancel Outgoing Mutual Request"
slug: cancel-outgoing-mutual-request
personas: [P-003]
epic: "Mutuals Graph & Degrees"
priority: should-have
complexity: low
tags: [graph, requests]
---

# US-204: Cancel Outgoing Mutual Request

## User Story

**As a** Social Connector (P-003)
**I want to** cancel a mutual request I previously sent before it is accepted
**So that** I can correct mistakes or change my mind without leaving unwanted pending requests

## Acceptance Criteria

- **Given** I have a pending outgoing mutual request to a specific user
  **When** I visit their profile or my outgoing requests list and tap "Cancel Request"
  **Then** the request is withdrawn, the button returns to "Add Mutual", and the recipient no longer sees it in their incoming list
