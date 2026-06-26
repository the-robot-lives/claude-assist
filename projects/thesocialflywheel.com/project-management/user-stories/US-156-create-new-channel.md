---
id: US-156
title: "Create a New Channel"
slug: create-new-channel
personas: [P-007]
epic: "Interest Channels"
priority: must-have
complexity: high
tags: [channels, create, ownership, moderation]
---

# US-156: Create a New Channel

## User Story

**As a** Channel Moderator
**I want to** create a new interest channel with a name, description, interest tags, and visibility setting
**So that** I can establish a dedicated community space for a topic that doesn't yet exist

## Acceptance Criteria

- **Given** I am on the channel creation form
  **When** I submit a channel name that already exists
  **Then** I receive an inline validation error before the form is submitted

- **Given** I complete the creation form with a unique name, at least one interest tag, and a description
  **When** I tap "Create Channel"
  **Then** the channel is created with me as the owner, I am automatically joined, and I am taken to the channel info page to continue setup

- **Given** the channel has been created
  **When** I view the channel for the first time
  **Then** I am prompted to set the channel rules and configure the opposing-view lane ratio before inviting others

## Notes
Required fields: name (max 64 chars), at least 1 interest tag, visibility (public/private). Optional: description (max 280 chars), avatar image, banner image. Default opposing-view ratio is the platform default until overridden.
