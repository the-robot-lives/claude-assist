---
id: US-184
title: "Gated Channel Membership with Approval"
slug: gated-channel-membership
personas: [P-007]
epic: "Interest Channels"
priority: should-have
complexity: high
tags: [channels, membership, approval, moderation, private]
---

# US-184: Gated Channel Membership with Approval

## User Story

**As a** Channel Moderator
**I want to** require moderator approval before new members can join my channel
**So that** I can maintain the quality and tone of a curated community

## Acceptance Criteria

- **Given** I have set the channel to "Approval Required" in channel settings
  **When** a user requests to join
  **Then** their request is queued in the moderator panel and the user sees a "Request Pending" state on the channel info page

- **Given** a join request is pending
  **When** I review and approve it from the moderator panel
  **Then** the user is immediately added as a member and receives a notification that their request was approved

- **Given** a join request is pending
  **When** I reject it
  **Then** the user receives a notification that their request was not approved, with no further explanation required

## Notes
Pending requests expire after 14 days if not acted upon; the user is notified of expiry. Moderators can filter the member panel by "Pending Approval." Approval mode does not affect existing members.
