---
id: US-154
title: "Join a Public Channel"
slug: join-public-channel
personas: [P-002]
epic: "Interest Channels"
priority: must-have
complexity: low
tags: [channels, join, membership]
---

# US-154: Join a Public Channel

## User Story

**As a** Niche Enthusiast
**I want to** join a public channel with a single tap
**So that** I can immediately start seeing that channel's posts in my feed

## Acceptance Criteria

- **Given** I am viewing a public channel's info page and I have not yet joined it
  **When** I tap the "Join" button
  **Then** my membership is confirmed, the button changes to "Joined," and the channel appears in my channel list

- **Given** I have just joined a channel
  **When** the channel has a newcomer onboarding flow configured
  **Then** I am shown the onboarding screen before being taken to the channel's main feed

- **Given** the channel has existing pinned posts
  **When** I join and view the channel for the first time
  **Then** pinned posts are shown at the top of the feed

## Notes
Joining is instantaneous for public channels. Private/approval channels follow a separate flow (US-184).
