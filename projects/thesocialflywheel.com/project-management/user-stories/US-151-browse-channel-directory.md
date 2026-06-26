---
id: US-151
title: "Browse Channel Directory"
slug: browse-channel-directory
personas: [P-002]
epic: "Interest Channels"
priority: must-have
complexity: medium
tags: [channels, discovery, browse]
---

# US-151: Browse Channel Directory

## User Story

**As a** Niche Enthusiast
**I want to** browse a paginated directory of all available interest channels
**So that** I can discover communities aligned with my specific passions

## Acceptance Criteria

- **Given** I am on the Channels discovery page
  **When** I scroll or paginate through the directory
  **Then** I see channel cards displaying name, member count, a short description, and primary interest tags

- **Given** the channel directory is loaded
  **When** I view a channel I have already joined
  **Then** it is visually distinguished (e.g., a "Joined" badge) from channels I have not joined

- **Given** I am browsing the directory
  **When** I tap a channel card
  **Then** I am taken to that channel's info page before committing to join

## Notes
Directory should support infinite scroll or paginated navigation with at least 20 channels per page. Channels with at least one mutual member within my 4th-degree network should be surfaced with a network proximity indicator.
