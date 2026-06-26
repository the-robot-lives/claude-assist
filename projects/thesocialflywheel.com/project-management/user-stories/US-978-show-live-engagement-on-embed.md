---
id: US-978
title: "Show Live Engagement on Embed"
slug: show-live-engagement-on-embed
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: could-have
complexity: medium
tags: [integrations, embed, engagement, real-time]
---

# US-978: Show Live Engagement on Embed

## User Story

**As a** Creator
**I want to** my embedded post to display a live reaction and reply count that updates in real time
**So that** external readers can see the social proof of engagement on my content.

## Acceptance Criteria

- **Given** an active embed on an external site
  **When** a new reaction or reply is added on Flywheel
  **Then** the embed updates its displayed counts within 60 seconds without a page reload.

- **Given** an embed with live counts enabled
  **When** the Flywheel post is deleted or set to private
  **Then** the embed displays a "Content no longer available" placeholder within 5 minutes.

## Notes

Live counts use a polling model (60-second interval) rather than WebSocket to minimize external site complexity. Embed authors can disable live counts via a URL parameter.
