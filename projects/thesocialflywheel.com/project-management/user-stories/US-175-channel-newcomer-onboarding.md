---
id: US-175
title: "Channel Onboarding Flow for Newcomers"
slug: channel-newcomer-onboarding
personas: [P-006]
epic: "Interest Channels"
priority: should-have
complexity: medium
tags: [channels, onboarding, newcomers, ux]
---

# US-175: Channel Onboarding Flow for Newcomers

## User Story

**As a** Quiet Consumer joining a channel for the first time
**I want to** be shown a short onboarding screen with the channel's purpose, rules, and key subtopics
**So that** I can orient myself quickly without having to hunt through settings

## Acceptance Criteria

- **Given** I join a channel that has a moderator-configured onboarding message
  **When** I complete joining
  **Then** I am shown a full-screen onboarding card with the welcome message, top 3 rules, and available subtopics before landing in the feed

- **Given** the channel has no custom onboarding message configured
  **When** I join
  **Then** I land directly in the channel feed (no blank onboarding screen is shown)

- **Given** I dismiss the onboarding card
  **When** I want to review it later
  **Then** I can find it under the channel's Info page as "Getting Started"

## Notes
The onboarding card should be skippable with a single tap. It is shown only once per membership; if the user leaves and rejoins, it should be shown again.
