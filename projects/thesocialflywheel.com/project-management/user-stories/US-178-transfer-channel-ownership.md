---
id: US-178
title: "Transfer Channel Ownership"
slug: transfer-channel-ownership
personas: [P-007]
epic: "Interest Channels"
priority: must-have
complexity: medium
tags: [channels, ownership, roles, moderation]
---

# US-178: Transfer Channel Ownership

## User Story

**As a** Channel Moderator
**I want to** transfer channel ownership to another member
**So that** the channel survives if I am no longer able to manage it actively

## Acceptance Criteria

- **Given** I am the channel owner
  **When** I open channel settings and select "Transfer Ownership"
  **Then** I am shown a list of current channel members (with moderator status highlighted) and can choose one to transfer ownership to

- **Given** I select a member and confirm the transfer
  **When** the action completes
  **Then** I become a regular moderator (not owner), the selected member becomes owner and receives a notification, and the change is logged in the moderation audit trail

- **Given** I attempt to leave the channel (US-155) while I am still the sole owner
  **When** I initiate leaving
  **Then** I am blocked with a message requiring me to transfer ownership before leaving

## Notes
A channel must always have exactly one owner. The owner can demote themselves by transferring but cannot remove the owner role without a successor.
