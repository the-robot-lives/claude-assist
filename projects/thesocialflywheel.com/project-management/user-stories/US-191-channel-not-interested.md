---
id: US-191
title: "Mark Channel as Not Interested"
slug: channel-not-interested
personas: [P-006]
epic: "Interest Channels"
priority: should-have
complexity: low
tags: [channels, discovery, dislikes, feed-control]
---

# US-191: Mark Channel as Not Interested

## User Story

**As a** Quiet Consumer
**I want to** dismiss a suggested or browsed channel as "Not Interested"
**So that** it stops appearing in suggestions and directory highlights without me having to block or report it

## Acceptance Criteria

- **Given** I am viewing a channel suggestion card
  **When** I tap the "Not Interested" option in its context menu
  **Then** the card is dismissed from my suggestions immediately and the channel is suppressed from future suggestion surfaces

- **Given** I have marked multiple channels as Not Interested
  **When** I navigate to Settings > Discovery Preferences
  **Then** I can see and manage my Not Interested list, including removing channels from it to allow them to resurface

## Notes
Not Interested is softer than a block — the channel still exists and the user can still visit it directly or via search. It only suppresses passive surfacing. The preference should persist indefinitely until explicitly cleared.
