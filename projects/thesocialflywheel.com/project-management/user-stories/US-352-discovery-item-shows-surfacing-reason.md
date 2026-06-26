---
id: US-352
title: "Discovery Item Shows Surfacing Reason"
slug: discovery-item-shows-surfacing-reason
personas: [P-001]
epic: "Discovery Engine"
priority: must-have
complexity: medium
tags: [discovery, transparency]
---

# US-352: Discovery Item Shows Surfacing Reason

## User Story

**As a** Bridge-Builder
**I want to** see a brief explanation of why a discovery item was surfaced
**So that** I understand the connection between the content and my interests or network

## Acceptance Criteria

- **Given** a discovery item appears in my feed
  **When** I view the item
  **Then** a label is shown indicating whether it was surfaced via an adjacent interest or via a specific degree of mutual connection

- **Given** the surfacing reason references a mutual connection
  **When** I read the label
  **Then** it identifies the degree of separation without exposing the specific intermediate accounts

## Notes
Reason text must be concise (≤12 words) to avoid cluttering the feed card.
