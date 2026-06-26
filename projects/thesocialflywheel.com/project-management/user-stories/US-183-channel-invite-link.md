---
id: US-183
title: "Generate Channel Invite Link"
slug: channel-invite-link
personas: [P-007]
epic: "Interest Channels"
priority: should-have
complexity: low
tags: [channels, invite, sharing, growth]
---

# US-183: Generate Channel Invite Link

## User Story

**As a** Channel Moderator
**I want to** generate a shareable invite link for my channel
**So that** I can grow the community by sharing the link outside the platform or with specific people

## Acceptance Criteria

- **Given** I am in channel settings
  **When** I tap "Generate Invite Link"
  **Then** a unique, copyable URL is created that, when visited by a logged-in user, takes them directly to the channel info page with a pre-populated "Join" action

- **Given** an invite link has been generated
  **When** I set an expiry (none, 7 days, 30 days) and tap "Create"
  **Then** the link respects the expiry and redirects to a "link expired" page after the set time

- **Given** I want to revoke access via the current invite link
  **When** I tap "Revoke Link"
  **Then** the existing link is immediately invalidated and a new one can be generated on demand

## Notes
Only one active invite link at a time per channel. Revoke-and-regenerate is the mechanism for rotating links. Links work for both public and private/approval channels (for private channels the join goes through approval flow).
