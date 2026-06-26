---
id: US-160
title: "Create Subtopic Within a Channel"
slug: create-channel-subtopic
personas: [P-007]
epic: "Interest Channels"
priority: should-have
complexity: medium
tags: [channels, subtopics, moderation, organization]
---

# US-160: Create Subtopic Within a Channel

## User Story

**As a** Channel Moderator
**I want to** create named subtopics within my channel
**So that** members can organize their posts and conversations around distinct facets of the channel's main interest

## Acceptance Criteria

- **Given** I am in channel moderation settings
  **When** I create a subtopic with a name and optional description
  **Then** it appears as a browsable section within the channel, and members can assign their posts to it

- **Given** I have created multiple subtopics
  **When** a member views the channel
  **Then** they see a subtopic navigation bar or list allowing them to filter the feed to a single subtopic

## Notes
Maximum of 25 subtopics per channel. Subtopic names max 48 chars. The "General" subtopic exists by default and cannot be deleted, only renamed.
