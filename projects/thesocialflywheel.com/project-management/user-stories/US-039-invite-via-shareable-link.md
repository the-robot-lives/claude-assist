---
id: US-039
title: "Invite via Shareable Link"
slug: invite-via-shareable-link
personas: [P-003, P-009, P-004]
epic: "Onboarding & Account Setup"
priority: should-have
complexity: low
tags: [invite, referral, link, onboarding]
---

# US-039: Invite via Shareable Link

## User Story

**As a** social connector
**I want to** share a personal invite link via any app on my device
**So that** I can bring friends onto Flywheel outside the contacts import flow

## Acceptance Criteria

- **Given** I tap "Share invite link" during onboarding
  **When** the share sheet opens
  **Then** a pre-filled message with my unique referral link is ready to send via any installed app.

- **Given** a friend clicks my invite link
  **When** they complete signup
  **Then** we are automatically shown as suggested connections with a "You were invited by…" note.

## Notes
Invite links are unique per user and do not expire. Track referral attribution for 30 days from link generation. Do not auto-send mutual requests — just surface as suggestions.
