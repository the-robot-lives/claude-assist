---
id: US-244
title: "Bulk Accept Pending Requests"
slug: bulk-accept-pending-requests
personas: [P-003]
epic: "Mutuals Graph & Degrees"
priority: could-have
complexity: medium
tags: [requests, pending, bulk]
---

# US-244: Bulk Accept Pending Requests

## User Story

**As a** Social Connector (P-003)
**I want to** select and accept multiple incoming mutual requests at once
**So that** I can efficiently clear a backlog of requests without tapping Accept on each one individually

## Acceptance Criteria

- **Given** I have 5 or more pending incoming requests
  **When** I enter the Incoming requests list
  **Then** a "Select all" checkbox and individual checkboxes appear for multi-select mode

- **Given** I have selected multiple requests
  **When** I tap "Accept selected (N)"
  **Then** all selected requests are accepted simultaneously and a summary toast confirms "N new mutuals added"

- **Given** bulk accept is in progress
  **When** any individual acceptance fails (e.g., requester cancelled mid-bulk)
  **Then** the remaining successful accepts proceed and a partial-failure message lists any that did not complete

## Notes
Bulk decline should be a separate, less prominent action to reduce the risk of accidental mass-decline.
