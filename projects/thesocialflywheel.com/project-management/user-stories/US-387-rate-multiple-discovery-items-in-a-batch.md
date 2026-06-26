---
id: US-387
title: "Rate Multiple Discovery Items in a Batch"
slug: rate-multiple-discovery-items-in-a-batch
personas: [P-006]
epic: "Discovery Engine"
priority: could-have
complexity: low
tags: [discovery, feedback, bulk]
---

# US-387: Rate Multiple Discovery Items in a Batch

## User Story

**As a** Quiet Consumer
**I want to** rate several discovery items at once from a batch review view
**So that** I can provide feedback efficiently without interrupting my normal feed reading flow

## Acceptance Criteria

- **Given** I tap "Rate Discovery" from the feed options menu
  **When** the batch review panel opens
  **Then** I see a compact list of up to ten recent discovery items I have not yet signaled, each with a thumbs-up and thumbs-down button

- **Given** I submit ratings in the batch review panel
  **When** the panel closes
  **Then** all recorded signals are applied to the discovery topic model in one operation

## Notes
Batch rating is available from the Discovery Settings page as well as the feed options menu.
